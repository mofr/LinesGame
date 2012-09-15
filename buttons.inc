const
  BTS_NORMAL=0;
  BTS_PRESSED=1;
  BTS_DISABLED=2;

  BTT_REGULAR=0;
  BTT_TOGGLE=1;
  BTT_SLIDER=2;

  BTA_NOTHING=0;
  BTA_ENTER=1;
  BTA_PRESS=2;
  BTA_CLICK=3;

type
Tbutton=record
	x,y,w,h:longint;
  img:pimage;
  dimg:pimage;
  state,btt:integer;
  prelighted,mp:boolean;
  //REGULAR
  act_proc:procedure;
  //TOGGLE
  var_toggle:^boolean;
  press_img:pimage;
  end;
Pbutton=^Tbutton;

procedure bt_setpos(bt:Pbutton;x,y:longint);
begin
bt^.x:=x;
bt^.y:=y;
end;

function bt_new(btt0:integer;img_path:ansistring;dimg0:pimage):Pbutton;
var nbt:Pbutton;
    i:integer;
begin
new(nbt);
with nbt^ do
begin
  x:=0;y:=0;
  mp:=false;
  state:=BTS_NORMAL;
  btt:=btt0;
  if loadimagefile(itdetect,img_path,img,0)=-1 then img:=nil
  else
  	begin
    w:=getimagewidth(img);
		h:=getimageheight(img);
    end;
  press_img:=img;
  dimg:=dimg0;
  act_proc:=nil;
  end;
bt_new:=nbt;
end;

procedure destroy_button(var bt:Pbutton);
begin
destroyimage(bt^.img);
dispose(bt);
bt:=nil;
end;

function inbutton(bt:Pbutton;x,y:longint):boolean;
begin
inbutton:=((x>bt^.x)and(x<bt^.x+bt^.w))and((y>bt^.y)and(y<bt^.y+bt^.h));
end;

procedure draw_button(bt:Pbutton);
var
  i,t:longint;
  timg:pimage;
begin
with bt^ do
if img<>nil then
	begin
  if state=BTS_PRESSED then timg:=cloneimage(press_img) else timg:=cloneimage(img);
  if prelighted then imageSADDcolor(timg,timg,rgbcolorrgb(30,30,30));
  composeimagec(dimg,timg,x+w div 2-getimagewidth(timg)div 2,y+h div 2-getimageheight(timg)div 2);
  destroyimage(timg);
  end;
end;

function update_button(bt:Pbutton;pmb,mb,mx,my:integer):integer;
{returns last action}
var ac:integer;
label end_;
begin
ac:=BTA_NOTHING;
if bt^.state=BTS_DISABLED then goto end_;
if inbutton(bt,mx,my)then bt^.prelighted:=true else bt^.prelighted:=false;
if bt^.prelighted and(mb=1)and(pmb=0) then bt^.mp:=true;
case bt^.btt of
  BTT_REGULAR:if bt^.prelighted and bt^.mp then
            begin
        if (mb=1)then bt^.state:=BTS_PRESSED;
        if (mb=0)and(pmb=1)then ac:=BTA_CLICK;
        end
    else bt^.state:=BTS_NORMAL;
  BTT_TOGGLE:if bt^.mp then case bt^.state of
    BTS_PRESSED:if bt^.prelighted and(mb=0)and(pmb=1)then
        begin
      bt^.state:=BTS_NORMAL;
      bt^.var_toggle^:=false;
      end;
    BTS_NORMAL:if bt^.prelighted and(mb=0)and(pmb=1)then
        begin
      bt^.state:=BTS_PRESSED;
      bt^.var_toggle^:=true;
      end;
    end;
  end;

if mb=0 then bt^.mp:=false;

case bt^.btt of
	BTT_REGULAR:if (ac<>BTA_NOTHING)and(bt^.act_proc<>nil) then bt^.act_proc();
  BTT_TOGGLE:if bt^.var_toggle^ then bt^.state:=BTS_PRESSED else bt^.state:=BTS_NORMAL;
  end;
end_:
update_button:=ac;
end;
