procedure save_settings;
var f:text;
	t:longint;
begin
assign(f,'configuration.txt');
{$i-}
rewrite(f);
{$i+}
if ioresult<>0 then begin writeln('Error: "configuration.txt" not found');end;
if ioresult=0 then
	begin
  writeln(f,'colors'+#39,kol_colors,#39);
  if draw_ballpath then t:=1 else t:=0;
  writeln(f,'drballpath',#39,t,#39);
  writeln(f,'famehallpath',#39,famehallpath,#39);
  writeln(f,'resx',#39,resx,#39);
  writeln(f,'resy',#39,resy,#39);
  close(f);
  end;
end;

procedure load_settings;
var f:text;
    s:ansistring;
    t:longint;
function get_val(s:ansistring):ansistring;
begin
get_val:=copy(s,pos(#39,s)+1,length(s)-pos(#39,s));
get_val:=copy(get_val,1,pos(#39,get_val)-1);
end;

begin
assign(f,'configuration.txt');
{$i-}
reset(f);
{$i+}
if ioresult<>0 then begin writeln('Error: "configure.txt" not found');end;
if ioresult=0 then
	begin
  repeat
    begin
    readln(f,s);
    if pos('famehallpath',s)<>0 then famehallpath:=get_val(s);
    if pos('colors',s)<>0 then val(get_val(s),kol_colors);
    if pos('resx',s)<>0 then val(get_val(s),resx);
    if pos('resy',s)<>0 then val(get_val(s),resy);
    if pos('drballpath',s)<>0 then
    	begin
    	val(get_val(s),t);
      if t=1 then draw_ballpath:=true else draw_ballpath:=false;
      end;
    end
    until eof(f);
  close(f);
  end;
end;

procedure game_options_loop;
var i:longint;
begin
pmb:=mb;
mb:=mousebutton;
mousecoords(mx,my);
if keypressed then case readkey of
	#27,#32,#13:return_to_gameprocess;
  end;
for i:=0 to MAX_BUTTONS-1 do if bt_opt[i]<>nil then update_button(bt_opt[i],pmb,mb,mx,my);
if currentmainloop=@game_options_loop then
	begin
  composeimage(scr_img_t,scr_img,0,0);
  for i:=0 to MAX_BUTTONS-1 do if bt_opt[i]<>nil then draw_button(bt_opt[i]);
  font.outtext(bt_opt[1]^.x+bt_opt[1]^.w+30,bt_opt[1]^.y+bt_opt[1]^.h div 2-font.fontheight div 2,'Draw ball path',rgbcolorrgb(180,130,10));
  putimage_wmask(scr_img_t,cursor[cur_cursor],cursor_mask[cur_cursor],mx,my);
  putimage(0,0,scr_img_t);
  end;
end;

procedure game_options;
begin
g_timer_stop(timer);
currentmainloop:=@game_options_loop;
create_scr_img_gameprocess(scr_img,false,false,false,false);
scr_img_t:=createimageWH(getmaxx+1,getmaxy+1);
for i:=0 to MAX_BUTTONS-1 do if bt_opt[i]<>nil then bt_opt[i]^.dimg:=scr_img_t;
font.setimage(scr_img_t);
end;
