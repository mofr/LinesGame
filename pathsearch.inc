type
	Tpath=record
  	len:integer;
    way:array[0..MAX_FIELD_X*MAX_FIELD_Y]of
    	record
      dx,dy:integer;
      end;
  	end;

function getpath(x1,y1,x2,y2:integer;var path:Tpath):boolean;
var ar:array[0..MAX_FIELD_X-1,0..MAX_FIELD_Y-1]of integer;
  found:boolean;

	procedure check_n_set(i,j:integer;val:longint);
	begin
	if not((i<0)or(i>field_x-1)or(j<0)or(j>field_y-1)) then
  	if (ar[i,j]=0) then
        begin
        ar[i,j]:=val;
        if (i=x1)and(j=y1)then found:=true;
        end;
	end;

	procedure create_wave_array;
	var i,j,k:integer;
	begin
	for i:=0 to field_x-1 do
	for j:=0 to field_y-1 do
  	if field[i,j]=FC_NIL then ar[i,j]:=0 else ar[i,j]:=-1;
	ar[x2,y2]:=1;
  ar[x1,y1]:=0;
	k:=0;
	while (k<=field_x*field_y)and not found do
    begin
    k:=k+1;
    i:=0;
      while (i<field_x)and not found do
          begin
          j:=0;
          while (j<field_y)and not found do
          	if ar[i,j]=k then
            begin
            if not found then check_n_set(i-1,j,k+1);
            if not found then check_n_set(i,j-1,k+1);
            if not found then check_n_set(i+1,j,k+1);
            if not found then check_n_set(i,j+1,k+1);
            j:=j+1;
            end else j:=j+1;
          i:=i+1;
          end;
    end;
	end;

var
  i,j,k,dir,min:integer;
  path_exist:boolean;
  a:array[0..3]of integer;
begin
create_wave_array;
path_exist:=true;
path.len:=0;
i:=x1;j:=y1;
with path do
while path_exist and((i<>x2)or(j<>y2))do
	begin
  if j-1>=0 then a[0]:=ar[i,j-1] else a[0]:=-1;
  if i+1<field_x then a[1]:=ar[i+1,j] else a[1]:=-1;
  if j+1<field_y then a[2]:=ar[i,j+1] else a[2]:=-1;
  if i-1>=0 then a[3]:=ar[i-1,j] else a[3]:=-1;
  dir:=-1;
  for k:=0 to 3 do
  	if (a[k]<>-1)and(a[k]<>0)and((dir=-1)or(a[k]<min))then
    	begin
    	dir:=k;
      min:=a[k];
      end;

  with way[len] do
  case dir of
  	0:begin dx:=0;dy:=-1;end;
    1:begin dx:=1;dy:=0;end;
		2:begin dx:=0;dy:=1;end;
    3:begin dx:=-1;dy:=0;end;
    -1:path_exist:=false;
    end;
  i:=i+way[len].dx;j:=j+way[len].dy;
  inc(len);
  end;
getpath:=path_exist;
end;