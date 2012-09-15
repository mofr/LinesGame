procedure game_about_loop;
var i:longint;
begin
pmb:=mb;
mb:=mousebutton;
mousecoords(mx,my);
if keypressed then case readkey of
	#27,#32,#13:return_to_gameprocess;
  end;
for i:=0 to MAX_BUTTONS-1 do if bt_ab[i]<>nil then update_button(bt_ab[i],pmb,mb,mx,my);
if currentmainloop=@game_about_loop then
	begin
  composeimage(scr_img_t,scr_img,0,0);
  for i:=0 to MAX_BUTTONS-1 do if bt_ab[i]<>nil then draw_button(bt_ab[i]);
  putimage_wmask(scr_img_t,cursor[cur_cursor],cursor_mask[cur_cursor],mx,my);
  putimage(0,0,scr_img_t);
  end;
end;

procedure game_about;
var img,img_mask:pimage;
	s:ansistring;
begin
g_timer_stop(timer);
currentmainloop:=@game_about_loop;
create_scr_img_gameprocess(scr_img,false,false,false,false);
loadimagefile(itdetect,'gfx\x.gif',img,0);
loadimagefile(itdetect,'gfx\x.gif',img_mask,2);
putimage_wmask(scr_img,img,img_mask,x1+(x2-x1)div 2-getimagewidth(img)div 2,getmaxy div 15);
with mainframe do
	begin
	draw_frame(scr_img,s1,s2,s3,s4,c1,c2,c3,c4,x1+(x2-x1)div 2-getimagewidth(img)div 2,0,x1+(x2-x1)div 2+getimagewidth(img)div 2,getmaxy div 15+getimageheight(img));
  draw_frame(scr_img,nil,s2,nil,nil,nil,c2,c3,nil,x1,0,x1+(x2-x1)div 2-getimagewidth(img)div 2,getmaxy div 15+getimageheight(img));
  draw_frame(scr_img,nil,nil,nil,s4,c1,nil,nil,c4,x1+(x2-x1)div 2+getimagewidth(img)div 2,0,getmaxx,getmaxy div 15+getimageheight(img));
  draw_frame(scr_img,s1,nil,nil,nil,c1,c2,nil,nil,x1+(x2-x1)div 2-getimagewidth(img)div 2,getmaxy div 15+getimageheight(img),x1+(x2-x1)div 2+getimagewidth(img)div 2,getmaxy);
  composeimagec(scr_img,c2,x1+(x2-x1)div 2-getimagewidth(img)div 2-getimagewidth(c2),getmaxy div 15+getimageheight(img));
  composeimagec(scr_img,c1,x1+(x2-x1)div 2+getimagewidth(img)div 2,getmaxy div 15+getimageheight(img));
  end;
scr_img_t:=createimageWH(getmaxx+1,getmaxy+1);
for i:=0 to MAX_BUTTONS-1 do if bt_ab[i]<>nil then bt_ab[i]^.dimg:=scr_img_t;
with font do
	begin
  setimage(scr_img);
  s:='Created by Egorov Alexander';
  outtext(x1+(x2-x1)div 2-textlength(s)div 2,2*getmaxy div 15+getimageheight(img),s,rgbcolorrgb(180,130,10));
  s:='24.01.07';
  outtext(x1+(x2-x1)div 2-textlength(s)div 2,2*getmaxy div 15+getimageheight(img)+5+fontheight,s,rgbcolorrgb(180,130,10));
  end;
destroyimage(img);
destroyimage(img_mask);
end;