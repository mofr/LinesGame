procedure putimage_wmask(bg,img,mask:pimage;x,y:longint);
var timg:pimage;
begin
timg:=cloneimage(img);
composeimage(timg,bg,-x,-y);
blendimagemaskimage(timg,img,mask,timg);
if bg<>nil then
	composeimagec(bg,timg,x,y)
else putimagec(x,y,timg);
destroyimage(timg);
end;

procedure draw_frame(dimg,s1,s2,s3,s4,c1,c2,c3,c4:pimage;x1,y1,x2,y2:longint);
var frimg:pimage;
	i:longint;
begin
frimg:=createimageWH(x2-x1,y2-y1);
fillimage(frimg,getimagetransparencycolor(frimg));
if s1<>nil then
for i:=0 to getimagewidth(frimg)div getimagewidth(s1)+1 do composeimagec(frimg,s1,i*getimagewidth(s1),0);
if s3<>nil then
for i:=0 to getimagewidth(frimg)div getimagewidth(s3)+1 do composeimagec(frimg,s3,i*getimagewidth(s3),getimageheight(frimg)-getimageheight(s3));
if s2<>nil then
for i:=0 to getimageheight(frimg)div getimageheight(s2)+1 do composeimagec(frimg,s2,getimagewidth(frimg)-getimagewidth(s2),i*getimageheight(s2));
if s4<>nil then
for i:=0 to getimageheight(frimg)div getimageheight(s4)+1 do composeimagec(frimg,s4,0,i*getimageheight(s4));
if c1<>nil then composeimagec(frimg,c1,0,0);
if c2<>nil then composeimagec(frimg,c2,getimagewidth(frimg)-getimagewidth(c2),0);
if c3<>nil then composeimagec(frimg,c3,getimagewidth(frimg)-getimagewidth(c3),getimageheight(frimg)-getimageheight(c3));
if c4<>nil then composeimagec(frimg,c4,0,getimageheight(frimg)-getimageheight(c4));
composeimagec(dimg,frimg,x1,y1);
destroyimage(frimg);
end;

procedure outtext_scaled(dimg:pimage;font:TfontFNT;text:ansistring;x0,y0,sx,sy:longint;color:longint);
var timg,timg2:pimage;
	koef:real;
begin
if sx=0 then koef:=sy/font.textheight(text)
 	else koef:=sy/font.textlength(text);
timg:=createimageWH(font.textlength(text),font.fontheight);
timg2:=createimageWH(round(getimagewidth(timg)*koef),round(getimageheight(timg)*koef));
font.setimage(timg);
//shadow
fillimage(timg,getimagetransparencycolor(timg));
font.outtext(0,0,text,rgbcolorrgb(15,15,15));
scaleimage(timg2,timg);
composeimagec(dimg,timg2,2+x0-getimagewidth(timg2)div 2,2+y0-getimageheight(timg2));
//main
fillimage(timg,getimagetransparencycolor(timg));
font.outtext(0,0,text,color);
scaleimage(timg2,timg);
composeimagec(dimg,timg2,x0-getimagewidth(timg2)div 2,y0-getimageheight(timg2));
//
destroyimage(timg);
destroyimage(timg2);
end;
