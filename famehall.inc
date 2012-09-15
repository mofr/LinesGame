function code_(s:ansistring):ansistring;
var t:char;
	i:integer;
begin
code_:='';
for i:=length(s) downto 1 do
	begin
  t:=chr(ord(s[i])+1);
  code_:=code_+t;
  end;
end;
function decode_(s:ansistring):ansistring;
var t:char;
	i:integer;
begin
decode_:='';
for i:=length(s) downto 1 do
	begin
  t:=chr(ord(s[i])-1);
  decode_:=decode_+t;
  end;
end;

function to_str(val:longint):ansistring;
begin
str(val,to_str);
end;

function getval(s:ansistring;c:char):ansistring;
begin
getval:=copy(s,pos(c,s)+1,length(s)-pos(c,s));
getval:=copy(getval,1,pos(c,getval)-1);
end;

function gethighscore(var name:ansistring):longint;
var f:text;
	t:longint;
  s:ansistring;
begin
assign(f,famehallpath);
{$i-}
reset(f);
{$i+}
if ioresult<>0 then begin writeln('Error: "',famehallpath,'" not found');end;
if ioresult=0 then
	begin
  gethighscore:=-1;
  while not eof(f)do
    begin
    readln(f,s);
    val(decode_(getval(s,#39)),t);
    if t>gethighscore then
    	begin
    	gethighscore:=t;
      name:=decode_(getval(s,'"'));
      end;
    end;
	if gethighscore<=0 then
  	begin
  	gethighscore:=0;
    name:='Highscore:';
    end;
  close(f);
  end;
end;

procedure famehall_add(name0:ansistring;score0:longint);
var
	ars:array[0..FAMEHALL_SIZE-1]of longint;
  arn:array[0..FAMEHALL_SIZE-1]of ansistring;
  f:text;
	i,k,j,t:longint;
  s:ansistring;
  min,minindx:longint;
begin
assign(f,famehallpath);
{$i-}
reset(f);
{$i+}
if ioresult<>0 then begin writeln('Error: "',famehallpath,'" not found');end;
if ioresult=0 then
	begin
  i:=0;
  minindx:=-1;min:=0;
  while not eof(f)and(i<FAMEHALL_SIZE)do
    begin
    readln(f,s);
    val(decode_(getval(s,#39)),ars[i]);
    arn[i]:=decode_(getval(s,'"'));
    if minindx=-1 then begin min:=ars[i];minindx:=i;end else
    if ars[i]<min then
    	begin
      minindx:=i;
      min:=ars[i];
      end;
    inc(i);
    end;
  close(f);
  if i<FAMEHALL_SIZE then
  	begin
    ars[i]:=score0;
    arn[i]:=name0;
    end else
  if (score0>min) then
  	begin
    ars[minindx]:=score0;
    arn[minindx]:=name0;
    end;
  //sorting
  if i>=FAMEHALL_SIZE then i:=FAMEHALL_SIZE-1;
  for k:=i-1 downto 0 do
  	for j:=0 to k do
    	if ars[j]<ars[j+1]then
      	begin
        t:=ars[j];ars[j]:=ars[j+1];ars[j+1]:=t;
        s:=arn[j];arn[j]:=arn[j+1];arn[j+1]:=s;
        end;
  //
  rewrite(f);
  for k:=0 to i do
  	writeln(f,'"'+code_(arn[k])+'"'+#39,code_(to_str(ars[k])),#39);
  close(f);
  end;
end;

procedure show_highscores_loop;
var i:integer;
begin
pmb:=mb;
mb:=mousebutton;
mousecoords(mx,my);
if keypressed then case readkey of
	#27,#32,#13:return_to_gameprocess;
	end;
for i:=0 to MAX_BUTTONS-1 do if bt_hs[i]<>nil then update_button(bt_hs[i],pmb,mb,mx,my);
if currentmainloop=@show_highscores_loop then
	begin
  composeimage(scr_img_t,scr_img,0,0);
	for i:=0 to MAX_BUTTONS-1 do if bt_hs[i]<>nil then draw_button(bt_hs[i]);
	putimage_wmask(scr_img_t,cursor[cur_cursor],cursor_mask[cur_cursor],mx,my);
  putimage(0,0,scr_img_t);
  end;
end;

procedure show_highscores;
var i,j:integer;
	ars:array[0..FAMEHALL_SIZE-1]of longint;
  arn:array[0..FAMEHALL_SIZE-1]of string[MAX_NAME_LEN];
  f:text;
  s:ansistring;
  title,titlemask:pimage;
  col:longint;
begin
g_timer_stop(timer);
currentmainloop:=@show_highscores_loop;
create_scr_img_gameprocess(scr_img,false,false,false,false);
scr_img_t:=createimageWH(getmaxx+1,getmaxy+1);
for i:=0 to MAX_BUTTONS-1 do if bt_hs[i]<>nil then bt_hs[i]^.dimg:=scr_img_t;
font.setimage(scr_img);
assign(f,famehallpath);
{$i-}
reset(f);
{$i+}
if ioresult<>0 then begin writeln('Error: "',famehallpath,'" not found');end;
if ioresult=0 then
	begin
  i:=0;
  while not eof(f)and(i<FAMEHALL_SIZE)do
    begin
    readln(f,s);
    val(decode_(getval(s,#39)),ars[i]);
    arn[i]:=decode_(getval(s,'"'));
    if i<3 then col:=rgbcolorrgb(250,200,20) else col:=rgbcolorrgb(180,130,10);
    font.outtext(x1+getmaxx div 4,getmaxy div 4+i*(font.fontheight+2),arn[i],col);
    font.outtext(x2-getmaxx div 4-font.textlength(to_str(ars[i])),getmaxy div 4+i*(font.fontheight+2),to_str(ars[i]),col);
    inc(i);
    end;
  close(f);
  end;
loadimagefile(itdetect,'gfx\highscores.gif',title,0);
loadimagefile(itdetect,'gfx\highscores.gif',titlemask,2);
putimage_wmask(scr_img,title,titlemask,x1+(x2-x1)div 2-getimagewidth(title)div 2,getmaxy div 7-getimageheight(title)div 2);
destroyimage(title);
destroyimage(titlemask);
end;
