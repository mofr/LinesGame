program lines_game;
uses graphix,gxmouse,gxtype,gximg,gximeff,gxcrt,gxdrw,glib,gxtext;
const
blur_filter:array[1..3,1..3] of byte=
            ((5,5,5),
             (5,5,5),
             (5,5,5));
  FAMEHALL_SIZE=20;
  MAX_NAME_LEN=15;

	MAX_FIELD_X=15;
  MAX_FIELD_Y=15;

	FC_NIL=0;
  FC_DIS=1;
  FC_RED=10;
  FC_GREEN=11;
  FC_BLUE=12;
  FC_BROWN=13;
  FC_BLACK=14;
  FC_PURPLE=15;
  FC_WHITE=16;
  FC_YELLOW=17;
  MAX_KOL_COLORS=8;
  FC_BOMB=18;

  AC_SELECT_BALL=0;
  AC_SELECT_BALL_PATH=1;
  AC_BALL_REPLACING=2;

  CURSOR_NORMAL=0;

  MAX_BUTTONS=10;
  MAX_KOL_SPARKS=10000;
  MAX_BOMB_KILLS=12;

  bomb_chance=4;
type
	Tspark=record
  	x,y,velx,vely:real;
    life:double;
  	end;
  Pspark=^Tspark;
var
	scr_img:pimage;
  main_quit,gameover_starting:boolean;
  currentmainloop:procedure;
  cur_cursor,i,resx,resy:integer;
  font:TfontFNT;
  playername,famehallpath:ansistring;
  scr_img_t:pimage;
  //game over
  gameover_timer:pgtimer;
  scr_img_gameover:pimage;
  //gameprocess
  field:array[0..MAX_FIELD_X-1,0..MAX_FIELD_Y-1]of byte;
  sel_dx,sel_dy,sel_dcount,selx,sely,ball_replace_step:integer;
  mx,my,mb,pmb,prcellmx,prcellmy,cellmx,cellmy,score,curhighscore:longint;
  lidername:ansistring;
  path_exist,create_balls:boolean;
  cur_action:byte;
  ball_replace_timer,timer:pgtimer;
  next_colors:array[0..MAX_FIELD_X*MAX_FIELD_Y-1]of byte;
  spark:array[0..MAX_KOL_SPARKS-1]of Pspark;
  //game settings
  field_x,field_y,kol_balls_gen,minlinelen,kol_colors:word;
  draw_ballpath:boolean;
  //interface
  mainframe:record
  	c1,c2,c3,c4,s1,s2,s3,s4:pimage;
  	end;
  x1,x2,y1,y2,field_x0,field_y0,scorey,highscorey,predicty:integer;
  cell_img,ball_step,gameover_img,gameover_img_mask,mainbg,fieldbg:pimage;
  ball_img,ball_img_mask:array[10..9+MAX_KOL_COLORS+1]of pimage;
  cursor:array[0..3]of pimage;
  cursor_mask:array[0..3]of pimage;

procedure gameover_loop;forward;
procedure gameprocess_loop;forward;
procedure create_scr_img_gameprocess(scr_img:pimage;dr_field,dr_buttons,dr_sparks,dr_cur:boolean);forward;
procedure return_to_gameprocess;forward;
  //
{$include graph.inc}
{$include pathsearch.inc}
{$include buttons.inc}
	var
  	path:Tpath;
    bt,bt_hs,bt_opt,bt_ab:array[0..MAX_BUTTONS-1]of Pbutton;
	//
{$include famehall.inc}
{$include game_options.inc}
{$include gameabout.inc}

procedure return_to_gameprocess;
begin
currentmainloop:=@gameprocess_loop;
destroyimage(scr_img_t);
save_settings;
end;

procedure clear_field;
var i,j:integer;
begin
for i:=0 to MAX_FIELD_X-1 do
	for j:=0 to MAX_FIELD_Y-1 do
  	field[i,j]:=FC_NIL;
end;

function get_kol_free_cells:integer;
var kol,i,j:integer;
begin
kol:=0;
for i:=0 to field_x-1 do
	for j:=0 to field_y-1 do if field[i,j]=FC_NIL then inc(kol);
get_kol_free_cells:=kol;
end;

procedure calc_next_colors;
var i:integer;
begin
for i:=0 to field_x*field_y-1 do next_colors[i]:=10+random(kol_colors);
end;

procedure gen_free_cell(var x,y:longint);
begin
if get_kol_free_cells<>0 then
repeat
	begin
  x:=random(field_x);y:=random(field_y);
  end
  until field[x,y]=FC_NIL;
end;

procedure create_new_balls(kol:integer);
var i,x,y:longint;
	b:boolean;
begin
randomize;
if get_kol_free_cells<kol then kol:=get_kol_free_cells;
b:=(random(round(100/bomb_chance))=0)and(score<>0);
if b then
	begin
  gen_free_cell(x,y);
  field[x,y]:=FC_BOMB;
  end;
for i:=1 to kol do
	begin
  gen_free_cell(x,y);
  field[x,y]:=next_colors[i-1];
  end;
calc_next_colors;
end;

procedure set_field_size(sx,sy:integer);
begin
field_x:=sx;
field_y:=sy;
field_x0:=x1+(x2-x1)div 2-field_x*getimagewidth(cell_img) div 2;
field_y0:=y1+(y2-y1)div 2-field_y*getimageheight(cell_img) div 2;
end;

procedure create_scr_img_gameprocess(scr_img:pimage;dr_field,dr_buttons,dr_sparks,dr_cur:boolean);
var i,j,dx,dy,k:integer;
begin
for i:=0 to x1 div getimagewidth(mainbg)+1 do
for j:=0 to getmaxy div getimageheight(mainbg)+1 do
	composeimage(scr_img,mainbg,i*getimagewidth(mainbg),j*getimageheight(mainbg));
for i:=0 to x2-x1 div getimagewidth(fieldbg)+1 do
for j:=0 to getmaxy div getimageheight(fieldbg)+1 do
	composeimage(scr_img,fieldbg,x1+i*getimagewidth(fieldbg),j*getimageheight(fieldbg));

if dr_field then
begin
for i:=0 to field_x-1 do
for j:=0 to field_y-1 do
	begin
  composeimage(scr_img,cell_img,field_x0+getimagewidth(cell_img)*i,field_y0+getimageheight(cell_img)*j);
  if field[i,j]in [10..9+MAX_KOL_COLORS+1] then
  	begin
    if (cur_action=AC_SELECT_BALL_PATH)and(i=selx)and(j=sely) then
    	begin dx:=sel_dx;dy:=sel_dy;end
    else begin dx:=0;dy:=0;end;
    if ball_img[field[i,j]]<>nil then
    putimage_wmask(scr_img,ball_img[field[i,j]],ball_img_mask[field[i,j]],
    	dx+field_x0+round(getimagewidth(cell_img)*(i+0.5))-getimagewidth(ball_img[field[i,j]])div 2,dy+field_y0+round(getimageheight(cell_img)*(j+0.5))-getimageheight(ball_img[field[i,j]])div 2);
    end;
	end;
i:=selx;j:=sely;
if draw_ballpath and path_exist then
with path do
for k:=0 to len-1 do
	begin
  i:=i+way[k].dx;
  j:=j+way[k].dy;
  composeimagec(scr_img,ball_step,field_x0+round(getimagewidth(cell_img)*(i+0.5))-getimagewidth(ball_step)div 2,field_y0+round(getimageheight(cell_img)*(j+0.5))-getimageheight(ball_step)div 2);
  end;
end;
outtext_scaled(scr_img,font,'Your Score:',x1 div 2,scorey div 3+getmaxx div 100,0,getmaxy div 25,rgbcolorrgb(180,130,10));
outtext_scaled(scr_img,font,to_str(score),x1 div 2,scorey*2 div 3+getmaxx div 100,0,getmaxy div 25,rgbcolorrgb(180,130,10));
outtext_scaled(scr_img,font,lidername,x1 div 2,highscorey+(getmaxy-highscorey) div 3+getmaxx div 100,0,getmaxy div 25,rgbcolorrgb(180,130,10));
outtext_scaled(scr_img,font,to_str(curhighscore),x1 div 2,highscorey+(getmaxy-highscorey)*2 div 3+getmaxx div 100,0,getmaxy div 25,rgbcolorrgb(180,130,10));

if dr_buttons then
for i:=0 to MAX_BUTTONS-1 do if bt[i]<>nil then draw_button(bt[i]);
k:=kol_balls_gen*(getimagewidth(ball_img[next_colors[0]])+10)-10;
for i:=0 to kol_balls_gen-1 do
	putimage_wmask(scr_img,ball_img[next_colors[i]],ball_img_mask[next_colors[i]],
  	x1 div 2-k div 2+i*(getimagewidth(ball_img[next_colors[i]])+10),predicty+(highscorey-predicty)div 2-getimageheight(ball_img[next_colors[i]])div 2);
with mainframe do
	begin
	draw_frame(scr_img,s1,s2,s3,s4,c1,c2,c3,c4,x1,y1,x2,y2);
  draw_frame(scr_img,s1,nil,s3,nil,nil,nil,nil,nil,0,0,x1,scorey);
  draw_frame(scr_img,s1,nil,s3,nil,nil,nil,nil,nil,0,scorey,x1,predicty);
  draw_frame(scr_img,s1,nil,s3,nil,nil,nil,nil,nil,0,predicty,x1,highscorey);
  draw_frame(scr_img,s1,nil,s3,nil,nil,nil,nil,nil,0,highscorey,x1,getmaxy);
	draw_frame(scr_img,s1,s2,s3,s4,c1,c2,c3,c4,0,0,x1,getmaxy);
  end;
if dr_sparks then
for i:=0 to MAX_KOL_SPARKS-1 do if spark[i]<>nil then
	with spark[i]^ do imagebar(scr_img,round(x),round(y),round(x)+random(2),round(y)+random(2),rgbcolorrgb(255,255,55+random(200)));
if dr_cur then putimage_wmask(scr_img,cursor[cur_cursor],cursor_mask[cur_cursor],mx,my);
end;

function infield(mx,my:longint;var rx,ry:longint):boolean;
begin
infield:=(mx>field_x0)and(mx<field_x0+(field_x)*getimagewidth(cell_img))and
	(my>field_y0)and(my<field_y0+(field_y)*getimageheight(cell_img));
if infield then
	begin
  rx:=(mx-field_x0)div getimagewidth(cell_img);
  ry:=(my-field_y0)div getimageheight(cell_img);
  end;
end;

procedure del_spark(var spark:Pspark);
begin
dispose(spark);
spark:=nil;
end;

procedure update_spark(var spark:Pspark;dtime:double);
begin
with spark^ do
	begin
  vely:=vely+5*dtime*10;
  x:=x+velx*dtime*10;
  y:=y+vely*dtime*10;
  if (y>=getmaxy)or(y<=0) then vely:=-vely;
  life:=life-dtime;
  end;
if spark^.life<0 then del_spark(spark);
end;

procedure spark_new(x0,y0,velx0,vely0,life0:real);
var i:longint;
begin
i:=0;
while (i<MAX_KOL_SPARKS)and(spark[i]<>nil)do inc(i);
if (i<MAX_KOL_SPARKS)and(spark[i]=nil) then
	begin
  new(spark[i]);
  if spark[i]<>nil then
  with spark[i]^ do
  	begin
    x:=x0;y:=y0;
    velx:=velx0;
    vely:=vely0;
    life:=life0;
    end;
  end;
end;

procedure new_game;
var i:longint;
begin
load_settings;
clear_field;
calc_next_colors;
create_new_balls(kol_balls_gen);
cur_action:=AC_SELECT_BALL;
score:=0;
for i:=0 to MAX_KOL_SPARKS-1 do del_spark(spark[i]);
curhighscore:=gethighscore(lidername);
end;

procedure quitattempt;
var continue:boolean;
	s:ansistring;
begin
g_timer_stop(timer);
font.setimage(scr_img);
s:='Are you really want to quit? (Y/N)';
continue:=false;
create_scr_img_gameprocess(scr_img,true,true,true,false);
filterimage(scr_img,scr_img,blur_filter,1,1,3,3,0);
outtext_scaled(scr_img,font,s,getmaxx div 2,getmaxy div 2,0,getmaxy div 20,rgbcolorrgb(180,130,10));
putimage(0,0,scr_img);
repeat
	begin
	if keypressed then
  case readkey of
  	'y','Y',#13:main_quit:=true;
    'n','N',#27:continue:=true;
    end;
  end until continue or main_quit;
end;

procedure gameover_loop;
var c:char;
  timg,timg2:pimage;
  s:ansistring;
  end_:boolean;
begin
end_:=false;
if gameover_starting and(g_timer_elapsed(gameover_timer,nil)<10) then
	begin
	filterimage(scr_img,scr_img,blur_filter,1,1,3,3,0);
  putimage_wmask(scr_img,gameover_img,gameover_img_mask,getmaxx div 2-getimagewidth(gameover_img)div 2,getmaxy div 3-getimageheight(gameover_img)div 2);
  end
else
	begin
  gameover_starting:=false;
  g_timer_stop(gameover_timer);
  end;
if keypressed then
	begin
  c:=readkey;
  case c of
  	#65..#90,#97..#122:if length(playername)<MAX_NAME_LEN then playername:=playername+c;
    #8:playername:=copy(playername,1,length(playername)-1);
    #13,#27:begin
			currentmainloop:=@gameprocess_loop;
  		g_timer_stop(gameover_timer);
      destroyimage(scr_img_gameover);
      if (c=#27)or(playername='') then playername:='unknown';
			famehall_add(playername,score);
      end_:=true;
      new_game;
    	end;
  	end;//case
  end;
if not end_ then
	begin
	composeimage(scr_img_gameover,scr_img,0,0);
	s:='Your name: ';
  outtext_scaled(scr_img_gameover,font,s+playername,getmaxx div 2,getmaxy div 2,0,getmaxy div 20,rgbcolorrgb(180,130,10));
	putimage(0,0,scr_img_gameover);
  end;
end;

function power(a,b:longint):longint;
var i:longint;
begin
power:=1;
for i:=1 to b do power:=power*a;
end;

procedure score_add(len:longint);
begin
inc(score,len+(len-5)*2+power(2,len-6));
end;

procedure sparks_flash(x0,y0,num:longint);
var i:longint;
begin
for i:=0 to num-1 do
	begin
	spark_new(x0+random(40)-20,y0+random(40)-20,(random(1200))/100-6,-random(500)/10,0.5+random(150)/100);
  end;
end;

procedure update_field;
var i,j,k,len,prev,lim:integer;

procedure kill_ver(x,y,len:integer);
var j:integer;
begin
for j:=y to y+len-1 do
	begin
	field[x,j]:=FC_NIL;
  sparks_flash(field_x0+round((x+0.5)*getimagewidth(cell_img)),field_y0+round((j+0.5)*getimageheight(cell_img)),(len+1)*10+random(3*len));
  end;
score_add(len);
create_balls:=false;
end;
procedure kill_hor(x,y,len:integer);
var i:integer;
begin
for i:=x to x+len-1 do
	begin
  field[i,y]:=FC_NIL;
  sparks_flash(field_x0+round((i+0.5)*getimagewidth(cell_img)),field_y0+round((y+0.5)*getimageheight(cell_img)),(len+1)*10+random(3*len));
  end;
score_add(len);
create_balls:=false;
end;
procedure kill_diag(x,y,len,d:integer);
var k:integer;
begin
k:=0;
while k<len do
	begin
  field[x+k*d,y+k]:=FC_NIL;
  sparks_flash(field_x0+round((x+k*d+0.5)*getimagewidth(cell_img)),field_y0+round((y+k+0.5)*getimageheight(cell_img)),(len+1)*15+random(3*len));
  inc(k);
  end;
score_add(len);
create_balls:=false;
end;

begin
randomize;
//vertical
for i:=0 to field_x-1 do
	begin
  len:=1;
  prev:=field[i,0];
	for j:=1 to field_y-1 do
    if prev=field[i,j]then inc(len) else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_ver(i,j-len,len);
      len:=1;
      prev:=field[i,j];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_ver(i,j-len+1,len);
  end;
//horizontal
for j:=0 to field_y-1 do
	begin
  len:=1;
  prev:=field[0,j];
  for i:=1 to field_x-1 do
  	if prev=field[i,j]then inc(len) else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_hor(i-len,j,len);
      len:=1;
      prev:=field[i,j];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_hor(i-len+1,j,len);
  end;
//diagonal L
if field_x<field_y then lim:=field_x else lim:=field_y;
for k:=0 to field_y-minlinelen do
	begin
  len:=1;
  prev:=field[0,k];
  for j:=1 to lim-1-k do
  	if prev=field[j,j+k]then inc(len)else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(j-len,j+k-len,len,1);
      len:=1;
      prev:=field[j,j+k];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(j-len+1,j+k-len+1,len,1);
  end;
for k:=1 to field_x-minlinelen do
	begin
  len:=1;
  prev:=field[k,0];
  for j:=1 to lim-1-k do
  	if prev=field[j+k,j]then inc(len)else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(j+k-len,j-len,len,1);
      len:=1;
      prev:=field[j+k,j];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(j+k-len+1,j-len+1,len,1);
  end;
//diagonal R
for k:=minlinelen-1 to lim-1 do
	begin
  len:=1;
  prev:=field[k,0];
  for j:=1 to k do
  	if prev=field[k-j,j]then inc(len)else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(k-j+len,j-len,len,-1);
      len:=1;
      prev:=field[k-j,j];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(k-j+len-1,j-len+1,len,-1);
  end;
for k:=minlinelen-1 to lim-2 do
	begin
  len:=1;
  prev:=field[field_x-1,field_y-1-k];
  for j:=1 to k do
    if prev=field[field_x-1-j,field_y-1-k+j]then inc(len)else
    	begin
      if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(field_x-1-j+len,field_y-1-k+j-len,len,-1);
      len:=1;
      prev:=field[field_x-1-j,field_y-1-k+j];
      end;
  if (prev<>FC_NIL)and(len>=minlinelen) then kill_diag(field_x-1-j+len-1,field_y-1-k+j-len+1,len,-1);
  end;
//
end;//procedure

var kol_bomb_kills:integer;
procedure explode_bomb(cx,cy:integer);
var i,j,x0,y0,lx,ly:integer;
begin
g_timer_stop(timer);
field[cx,cy]:=FC_NIL;
sparks_flash(field_x0+round((cx+0.5)*getimagewidth(cell_img)),field_y0+round((cy+0.5)*getimageheight(cell_img)),500);
x0:=cx-1;y0:=cy-1;
lx:=x0+3-1;ly:=y0+3-1;
if x0<0 then x0:=0;
if y0<0 then y0:=0;
if lx>=field_x then lx:=field_x-1;
if ly>=field_y then ly:=field_y-1;
for i:=x0 to lx do
for j:=y0 to ly do
	if field[i,j]<>FC_NIL then
	begin
  sparks_flash(field_x0+round((i+0.5)*getimagewidth(cell_img)),field_y0+round((j+0.5)*getimageheight(cell_img)),150);
  if field[i,j]=FC_BOMB then explode_bomb(i,j);
  field[i,j]:=FC_NIL;
  inc(kol_bomb_kills);
  end;
end;

procedure gameprocess_loop;
var mouse_in_field:boolean;
	i:longint;
begin
g_timer_stop(timer);
g_timer_reset(timer);
g_timer_start(timer);
prcellmx:=cellmx;
prcellmy:=cellmy;
pmb:=mb;
mb:=mousebutton;
mousecoords(mx,my);
mouse_in_field:=infield(mx,my,cellmx,cellmy);
if keypressed then case readkey of
	#27:quitattempt;
  #32:create_new_balls(kol_balls_gen);
  #59:game_about;
  end;
if currentmainloop=@gameprocess_loop then
begin
if cur_action=AC_SELECT_BALL_PATH then
	begin
	if (prcellmx<>cellmx)or(prcellmy<>cellmy)then
  	path_exist:=(field[cellmx,cellmy]=FC_NIL)and mouse_in_field and getpath(selx,sely,cellmx,cellmy,path);
  end else path_exist:=false;

if (mb=0)and(pmb=2)and(cur_action=AC_SELECT_BALL_PATH)then
  cur_action:=AC_SELECT_BALL;
if (mb=0)and(pmb=1) then
case cur_action of
  AC_SELECT_BALL:if mouse_in_field and(field[cellmx,cellmy]in[10..9+MAX_KOL_COLORS+1])then
  	begin
    selx:=cellmx;sely:=cellmy;
    cur_action:=AC_SELECT_BALL_PATH;
    sel_dx:=0;
    sel_dy:=0;
    sel_dcount:=0;
    end;
  AC_SELECT_BALL_PATH:if mouse_in_field then
  	begin
    if (field[selx,sely]=FC_BOMB)and(cellmx=selx)and(cellmy=sely)then
    	begin
      kol_bomb_kills:=1;
      explode_bomb(selx,sely);
      if kol_bomb_kills>MAX_BOMB_KILLS then kol_bomb_kills:=MAX_BOMB_KILLS;
      score_add(kol_bomb_kills);
      cur_action:=AC_SELECT_BALL;
      end
    else
    if(field[cellmx,cellmy]=FC_NIL)and path_exist then
  		begin
  		cur_action:=AC_BALL_REPLACING;
      ball_replace_step:=0;
      g_timer_start(ball_replace_timer);
    	end else
    if field[cellmx,cellmy]<>FC_NIL then
    		begin
      	if (selx=cellmx)and(sely=cellmy)then cur_action:=AC_SELECT_BALL;
      	selx:=cellmx;sely:=cellmy;
      	end;

    end;//AC_SELECT_BALL_PATH
  end;//case

create_balls:=false;

if cur_action=AC_SELECT_BALL_PATH then
case field[selx,sely] of
  FC_RED..FC_YELLOW:begin
  case sel_dcount of
  	0..8:dec(sel_dy);
    9..12:begin dec(sel_dx);inc(sel_dy);end;
    13..16:begin inc(sel_dx);inc(sel_dy);end;
    17..20:begin inc(sel_dx);dec(sel_dy);end;
    21..24:begin dec(sel_dx);dec(sel_dy);end;
  	end;
  inc(sel_dcount);
  if sel_dcount>24 then sel_dcount:=9;
  end;
  FC_BOMB:begin
  	spark_new(field_x0+round((selx+0.5)*getimagewidth(cell_img)),field_y0+round((sely+0.5)*getimageheight(cell_img))-getimageheight(ball_img[field[selx,sely]])div 2,
  		random(1000)/100-5,-random(300)/10,random(100)/100);
    sel_dx:=0;sel_dy:=0;
    sel_dcount:=0;
    end;
end;
if cur_action=AC_BALL_REPLACING then
	begin
  if g_timer_elapsed(ball_replace_timer,nil)>0.01 then
  with path do
  	begin
    g_timer_reset(ball_replace_timer);
  	field[selx+way[ball_replace_step].dx,sely+way[ball_replace_step].dy]:=field[selx,sely];
  	field[selx,sely]:=FC_NIL;
    selx:=selx+way[ball_replace_step].dx;
    sely:=sely+way[ball_replace_step].dy;
    inc(ball_replace_step);
    if ball_replace_step=len then
    	begin
    	cur_action:=AC_SELECT_BALL;
      create_balls:=field[selx,sely]<>FC_BOMB;
      if field[selx,sely]=FC_BOMB then
      	begin
        kol_bomb_kills:=1;
      	explode_bomb(selx,sely);
        if kol_bomb_kills>MAX_BOMB_KILLS then kol_bomb_kills:=MAX_BOMB_KILLS;
        score_add(kol_bomb_kills);
        end;
      g_timer_stop(ball_replace_timer);
      end;
  	end;
  end;
create_scr_img_gameprocess(scr_img,true,true,true,true);
for i:=0 to MAX_BUTTONS-1 do if bt[i]<>nil then update_button(bt[i],pmb,mb,mx,my);
putimage(0,0,scr_img);
if cur_action<>AC_BALL_REPLACING then update_field;
if create_balls then create_new_balls(kol_balls_gen);
for i:=0 to MAX_KOL_SPARKS-1 do if spark[i]<>nil then update_spark(spark[i],g_timer_elapsed(timer,nil));
if get_kol_free_cells=0 then
	begin
  g_timer_stop(timer);
  scr_img_gameover:=createimageWH(getimagewidth(scr_img),getimageheight(scr_img));
  playername:='';
  gameover_starting:=true;
  create_scr_img_gameprocess(scr_img,true,true,true,false);
  g_timer_reset(gameover_timer);
  g_timer_start(gameover_timer);
	currentmainloop:=@gameover_loop;
  end;
end;
end;

begin
ball_replace_timer:=g_timer_new;
gameover_timer:=g_timer_new;
timer:=g_timer_new;
load_settings;
initgraphix(ig_vesa,ig_lfb);
setmodegraphix(resx,resy,ig_col32);
initmouse;
disablemouse;
scr_img:=createimageWH(getmaxx+1,getmaxy+1);
//
x1:=getmaxx div 4;y1:=0;
x2:=getmaxx;y2:=getmaxy;
scorey:=getmaxy div 5;
highscorey:=getmaxy*4 div 5;
//
loadimagefile(itdetect,'gfx\ball_step.gif',ball_step,0);
loadimagefile(itdetect,'gfx\ball-red.gif',ball_img[FC_RED],0);
loadimagefile(itdetect,'gfx\ball-red.gif',ball_img_mask[FC_RED],2);
loadimagefile(itdetect,'gfx\ball-green.gif',ball_img[FC_GREEN],0);
loadimagefile(itdetect,'gfx\ball-green.gif',ball_img_mask[FC_GREEN],2);
loadimagefile(itdetect,'gfx\ball-blue.gif',ball_img[FC_BLUe],0);
loadimagefile(itdetect,'gfx\ball-blue.gif',ball_img_mask[FC_BLUE],2);
loadimagefile(itdetect,'gfx\ball-purple.gif',ball_img[FC_PURPLE],0);
loadimagefile(itdetect,'gfx\ball-purple.gif',ball_img_mask[FC_PURPLE],2);
loadimagefile(itdetect,'gfx\ball-brown.gif',ball_img[FC_BROWN],0);
loadimagefile(itdetect,'gfx\ball-brown.gif',ball_img_mask[FC_BROWN],2);
loadimagefile(itdetect,'gfx\ball-black.gif',ball_img[FC_BLACK],0);
loadimagefile(itdetect,'gfx\ball-black.gif',ball_img_mask[FC_BLACK],2);
loadimagefile(itdetect,'gfx\ball-white.gif',ball_img[FC_WHITE],0);
loadimagefile(itdetect,'gfx\ball-white.gif',ball_img_mask[FC_WHITE],2);
loadimagefile(itdetect,'gfx\ball-yellow.gif',ball_img[FC_YELLOW],0);
loadimagefile(itdetect,'gfx\ball-yellow.gif',ball_img_mask[FC_YELLOW],2);
loadimagefile(itdetect,'gfx\ball-bomb.gif',ball_img[FC_BOMB],0);
loadimagefile(itdetect,'gfx\ball-bomb.gif',ball_img_mask[FC_BOMB],2);
loadimagefile(itdetect,'gfx\cell.gif',cell_img,0);
loadimagefile(itdetect,'gfx\cursor0.gif',cursor[CURSOR_NORMAL],0);
loadimagefile(itdetect,'gfx\cursor0.gif',cursor_mask[CURSOR_NORMAL],2);
loadimagefile(itdetect,'gfx\gameover.gif',gameover_img,0);
loadimagefile(itdetect,'gfx\gameover.gif',gameover_img_mask,2);
loadimagefile(itdetect,'gfx\bg1.gif',mainbg,0);
loadimagefile(itdetect,'gfx\bg2.gif',fieldbg,0);
with mainframe do
	begin
  loadimagefile(itdetect,'gfx\frame.gif',s1,1);
  loadimagefile(itdetect,'gfx\frame.gif',s2,2);
  loadimagefile(itdetect,'gfx\frame.gif',s3,3);
  loadimagefile(itdetect,'gfx\frame.gif',s4,4);
  loadimagefile(itdetect,'gfx\frame.gif',c1,5);
  loadimagefile(itdetect,'gfx\frame.gif',c2,6);
  loadimagefile(itdetect,'gfx\frame.gif',c3,7);
  loadimagefile(itdetect,'gfx\frame.gif',c4,8);
  end;
//BUTTONS
for i:=0 to MAX_BUTTONS-1 do bt[i]:=nil;
for i:=0 to MAX_BUTTONS-1 do bt_hs[i]:=nil;
for i:=0 to MAX_BUTTONS-1 do bt_opt[i]:=nil;
i:=0;
bt[i]:=bt_new(BTT_REGULAR,'gfx\but1.gif',scr_img);
bt_setpos(bt[i],x1 div 2-bt[i]^.w div 2,scorey+20+getmaxx div 100);
bt[i]^.act_proc:=@new_game;
inc(i);
bt[i]:=bt_new(BTT_REGULAR,'gfx\buthi.gif',scr_img);
bt_setpos(bt[i],x1 div 2-bt[i]^.w div 2,bt[i-1]^.y+bt[i-1]^.h+getmaxx div 100);
bt[i]^.act_proc:=@show_highscores;
inc(i);
bt[i]:=bt_new(BTT_REGULAR,'gfx\butopt.gif',scr_img);
bt_setpos(bt[i],x1 div 2-bt[i]^.w div 2,bt[i-1]^.y+bt[i-1]^.h+getmaxx div 100);
bt[i]^.act_proc:=@game_options;
inc(i);
bt[i]:=bt_new(BTT_REGULAR,'gfx\butex.gif',scr_img);
bt_setpos(bt[i],x1 div 2-bt[i]^.w div 2,bt[i-1]^.y+bt[i-1]^.h+getmaxx div 100);
bt[i]^.act_proc:=@quitattempt;
//
predicty:=bt[i]^.y+bt[i]^.h+20+getmaxx div 100;
//
i:=0;
bt_hs[i]:=bt_new(BTT_REGULAR,'gfx\butcont.gif',nil);
bt_setpos(bt_hs[i],x1 div 2-bt_hs[i]^.w div 2,scorey+20+getmaxx div 100);
bt_hs[i]^.act_proc:=@return_to_gameprocess;
//
i:=0;
bt_opt[i]:=bt_new(BTT_REGULAR,'gfx\butcont.gif',nil);
bt_setpos(bt_opt[i],x1 div 2-bt_opt[i]^.w div 2,scorey+20+getmaxx div 100);
bt_opt[i]^.act_proc:=@return_to_gameprocess;
inc(i);
bt_opt[i]:=bt_new(BTT_TOGGLE,'gfx\buttoggle.gif',nil);
loadimagefile(itdetect,'gfx\pr_buttoggle.gif',bt_opt[i]^.press_img,0);
bt_setpos(bt_opt[i],x1+(x2-x1)div 7,getmaxy div 5);
bt_opt[i]^.var_toggle:=@draw_ballpath;
//
i:=0;
bt_ab[i]:=bt_new(BTT_REGULAR,'gfx\butcont.gif',nil);
bt_setpos(bt_ab[i],x1 div 2-bt_ab[i]^.w div 2,scorey+20+getmaxx div 100);
bt_ab[i]^.act_proc:=@return_to_gameprocess;
//
font.loadfont('fontvga.fnt');
set_field_size(10,10);
minlinelen:=5;
kol_balls_gen:=3;
main_quit:=false;

cur_cursor:=CURSOR_NORMAL;
new_game;
//
currentmainloop:=@gameprocess_loop;
g_timer_start(timer);
repeat currentmainloop() until main_quit;
destroyimage(scr_img);
donegraphix;
end.
