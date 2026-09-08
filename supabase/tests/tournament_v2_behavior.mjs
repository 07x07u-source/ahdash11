// Local, ephemeral PostgreSQL/WASM tests of the exact Phase 5 function bodies.
// This is NOT a substitute for Supabase auth/RLS, pgTAP, or multi-connection tests.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { PGlite } from '../../.codex-temp/phase5-sql/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite();
const owner = '10000000-0000-4000-8000-000000000001';
const outsider = '10000000-0000-4000-8000-000000000002';
let count = 0;
const id = (n) => `20000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const source = await readFile(new URL('../migrations/20260831000200_tournaments_v1.sql', import.meta.url), 'utf8');
const patch = await readFile(new URL('../migrations/20260905000100_tournament_bracket_safety_v2.sql', import.meta.url), 'utf8');
await db.exec(`create schema extensions; create domain extensions.citext as text;
create role authenticated; create role anon;
create table public.profiles(id uuid primary key);
insert into public.profiles values ('${owner}'), ('${outsider}');
create function public.require_active_user() returns public.profiles language sql as
$$ select * from public.profiles where id = current_setting('test.actor')::uuid $$;
create function public.assert_rate_limit(text,text,integer,interval) returns void language sql as $$ select $$;
create function public.save_tournament_bracket(uuid,jsonb,jsonb) returns boolean language sql as $$ select true $$;
create function public.confirm_tournament_match_result(uuid,uuid,integer,integer,uuid,uuid) returns boolean language sql as $$ select true $$;
select set_config('test.actor','${owner}',false);`);
await db.exec(source.slice(source.indexOf('create type'), source.indexOf('create index')));
await db.exec(patch);
async function check(name, fn) { await fn(); console.log(`PASS ${++count}: ${name}`); }
async function rejects(sql, args, code) {
  await assert.rejects(() => db.query(sql, args), (e) => e.code === code);
}
async function seed(n, capacity = 4) {
  await db.query(`insert into public.tournaments(id,organizer_id,name,capacity,players_per_team)
    values ($1,$2,'Test tournament',$3,2)`, [id(n), owner, capacity]);
  const teams = [0,1,2,3].map((i) => ({id:id(n+10+i), name:`Team ${i}`, players:[`Player ${i}`], seed:i+1, approved:true}));
  const matches = [
    {id:id(n+20),round:1,position:0,status:'ready',team_a_id:teams[0].id,team_b_id:teams[3].id,next_match_id:id(n+22),next_slot:0},
    {id:id(n+21),round:1,position:1,status:'ready',team_a_id:teams[1].id,team_b_id:teams[2].id,next_match_id:id(n+22),next_slot:1},
    {id:id(n+22),round:2,position:0,status:'pending'},
  ];
  return {id:id(n),teams,matches};
}
const call = 'select public.save_tournament_bracket_v2($1,$2::jsonb,$3::jsonb)';
const args = (f) => [f.id,JSON.stringify(f.teams),JSON.stringify(f.matches)];
const confirm = 'select public.confirm_tournament_match_result_v2($1,$2,$3,$4,$5,$6)';
const f = await seed(100);
await db.query(`insert into public.tournament_teams(id,tournament_id,owner_user_id,name,status) values ($1,$2,$3,$4,'approved')`,[f.teams[0].id,f.id,outsider,f.teams[0].name]);
await db.query(`insert into public.tournament_players(id,tournament_id,team_id,user_id,display_name,is_captain) values ($1,$2,$3,$4,'Captain',true)`,[id(199),f.id,f.teams[0].id,outsider]);
await check('outsider cannot draw', async () => {
  await db.query("select set_config('test.actor',$1,false)",[outsider]);
  await rejects(call,args(f),'42501');
  await db.query("select set_config('test.actor',$1,false)",[owner]);
});
for (const [name, mutate] of [
  ['null teams', x=>x.teams=null],
  ['duplicate team id', x=>x.teams[1].id=x.teams[0].id],
  ['null seed', x=>x.teams[0].seed=null],
  ['null match round', x=>x.matches[0].round=null],
  ['duplicate first-round team', x=>x.matches[1].team_a_id=x.matches[0].team_a_id],
  ['self pairing', x=>x.matches[0].team_b_id=x.matches[0].team_a_id],
  ['wrong next slot', x=>x.matches[0].next_slot=1],
  ['invented advancement', x=>x.matches[2].team_a_id=x.teams[0].id],
  ['fake bye winner', x=>{x.matches[0].status='bye';x.matches[0].winner_id=x.teams[0].id;}],
  ['missing approved team', x=>{x.teams[0].id=id(900);x.matches[0].team_a_id=id(900);}],
  ['duplicate player', x=>x.teams[1].players=['Same','same']],
]) {
  await check(name, async()=> {
    const invalid=structuredClone(f); mutate(invalid);
    await assert.rejects(()=>db.query(call,args(invalid)));
    assert.equal((await db.query('select count(*)::int n from public.tournament_players')).rows[0].n,1);
  });
}
await check('draw preserves existing captain/user/player/team identities',async()=>{
  await db.query(call,args(f));
  const p=(await db.query('select * from public.tournament_players where id=$1',[id(199)])).rows[0];
  assert.equal(p.user_id,outsider); assert.equal(p.is_captain,true); assert.equal(p.team_id,f.teams[0].id);
  assert.equal((await db.query('select owner_user_id from public.tournament_teams where id=$1',[f.teams[0].id])).rows[0].owner_user_id,outsider);
  assert.equal((await db.query('select count(*)::int n from public.tournament_players')).rows[0].n,4);
});
await check('exact draw retry does not duplicate rows or events',async()=>{
  await db.query(call,args(f));
  assert.equal((await db.query('select count(*)::int n from public.tournament_events')).rows[0].n,1);
});
await check('live redraw conflict rejected',async()=>{
  const changed=structuredClone(f);changed.matches[0].id=id(998);
  await rejects(call,args(changed),'55000');
});
for(const [name,scores,winner] of [
  ['null score',[null,0],f.teams[0].id], ['negative score',[-1,0],f.teams[0].id],
  ['null winner',[2,1],null], ['losing winner',[2,1],f.teams[3].id],
  ['foreign winner',[2,1],id(999)],
]) await check(name,()=>rejects(confirm,[f.id,f.matches[0].id,...scores,winner,null],'22023'));
await check('outsider cannot confirm',async()=>{
  await db.query("select set_config('test.actor',$1,false)",[outsider]);
  await rejects(confirm,[f.id,f.matches[0].id,2,1,f.teams[0].id,null],'42501');
  await db.query("select set_config('test.actor',$1,false)",[owner]);
});
await check('confirmation advances exactly once; conflicting retry rejected',async()=>{
  const result=[f.id,f.matches[0].id,2,1,f.teams[0].id,null];
  await db.query(confirm,result);await db.query(confirm,result);
  await rejects(confirm,[f.id,f.matches[0].id,3,1,f.teams[0].id,null],'55000');
  const next=(await db.query('select * from public.tournament_matches where id=$1',[f.matches[2].id])).rows[0];
  assert.equal(next.team_a_id,f.teams[0].id);assert.equal(next.status,'pending');
  await rejects(call,args(f),'55000');
});
await check('semifinal and final commit champion without duplicate event',async()=>{
  await db.query(confirm,[f.id,f.matches[1].id,2,1,f.teams[1].id,null]);
  const result=[f.id,f.matches[2].id,2,1,f.teams[0].id,null];
  await db.query(confirm,result);await db.query(confirm,result);
  const event=(await db.query('select * from public.tournaments where id=$1',[f.id])).rows[0];
  assert.equal(event.status,'completed');assert.equal(event.champion_team_id,f.teams[0].id);
  assert.equal((await db.query('select count(*)::int n from public.tournament_events')).rows[0].n,4);
});
await check('old destructive RPC is not executable by authenticated',async()=>{
  const result=await db.query("select has_function_privilege('authenticated','public.save_tournament_bracket(uuid,jsonb,jsonb)','execute') allowed");
  assert.equal(result.rows[0].allowed,false);
});
for (const capacity of [4,8,16,32,64]) await check(`sparse ${capacity}-slot graph accepts empty byes and preserves two teams`,async()=>{
  const base=capacity*1000;
  const cup=id(base);
  await db.query(`insert into public.tournaments(id,organizer_id,name,capacity,players_per_team)
    values ($1,$2,'Sparse bracket',$3,2)`,[cup,owner,capacity]);
  const teams=[0,1].map(i=>({id:id(base+10+i),name:`Sparse ${i}`,seed:i+1,players:[],approved:true}));
  let order=[1,2];
  for(let size=4;size<=capacity;size*=2) order=order.flatMap(seed=>[seed,size+1-seed]);
  const matches=[];
  const rounds=Math.log2(capacity);
  const mid=(round,position)=>id(base+100+round*100+position);
  for(let round=1;round<=rounds;round++) for(let position=0;position<(capacity>>round);position++) {
    const feeders=matches.filter(m=>m.next_match_id===mid(round,position));
    const a=round===1 ? teams[order[position*2]-1]?.id??null : feeders.find(m=>m.next_slot===0)?.winner_id??null;
    const b=round===1 ? teams[order[position*2+1]-1]?.id??null : feeders.find(m=>m.next_slot===1)?.winner_id??null;
    const settled=round===1||feeders.every(m=>m.status==='bye');
    const status=a&&b?'ready':settled?'bye':'pending';
    matches.push({id:mid(round,position),round,position,status,team_a_id:a,team_b_id:b,
      winner_id:status==='bye'?(a??b):null,
      next_match_id:round<rounds?mid(round+1,Math.floor(position/2)):null,
      next_slot:round<rounds?position%2:null});
  }
  await db.query(call,args({id:cup,teams,matches}));
  const rows=(await db.query('select * from public.tournament_matches where tournament_id=$1',[cup])).rows;
  assert.equal(rows.length,capacity-1);
  assert.equal(rows.filter(m=>m.status==='ready').length,1);
  await db.query(call,args({id:cup,teams,matches}));
});
console.log(`${count}/${count} embedded PostgreSQL behavior checks passed. Auth/rate-limit stubs; Supabase pgTAP and concurrency not exercised.`);
await db.close();
