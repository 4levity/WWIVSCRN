{
WWIV Fileshow by Ivan Cooper
}

uses crt,dos;
type fname    = string[35];
     csetup   = array [0..9] of byte;
     defsetup = record
                  autofile  : fname;
                  defcolors : csetup;
                  defmono   : csetup;
                  SFX       : boolean;
                  defmode   : boolean;
                end;

var  dirstuff : searchrec;
     code     : integer;
     F        : Text;
     Count    : Byte;
     Line     : String;
     dummy    : char;
     Mask     : Pathstr;
     defaults : defsetup;
     esc      : boolean;
     dir      : dirstr;
     name     : namestr;
     ext      : extstr;

Const
     CTRP     : Char = #3;


Procedure showDir(Mask:PathStr);
Begin
  Count:=0;
  If mask='' then mask := '*.*';
  writeln('Directory of ',mask);
  FindFirst (Mask, Anyfile, DirStuff);
  While doserror = 0 do
  Begin
    if ((dirstuff.attr<>readonly) and
        (dirstuff.attr<>sysfile) and
        (dirstuff.attr<>hidden) and
        (dirstuff.attr<>volumeid) and
        (dirstuff.attr<>directory)) then
    begin
      Write(DirStuff.Name:20);
      Inc(Count);
      If Count=80 then
      Begin
        write('--MORE--');
        dummy:=readkey;
        if(ord(dummy)=0)then
          dummy:=readkey;
        gotoxy(1,wherey);
        clreol;
        Count:=0;
      end;
    end;
    FindNext (DirStuff);
  end;
end;

Function okname(F:Pathstr):Boolean;
Begin
  Okname:=(Pos('*',F)+pos('?',F)+pos(' ',F)+pos('>',F)+
           pos('<',F)+pos('/',F)+pos('+',f)=0);
end;

Function Exist (F:PathStr):Boolean;
var S:Searchrec;
begin
  findfirst (f,anyfile,s);
  Exist:=((doserror=0) and (s.attr<>readonly)and(s.attr<>sysfile)and
                           (s.attr<>hidden)and(s.attr<>volumeid) and
                           (s.attr<>directory));
end;

procedure loaddefaults;
var f:file of defsetup;
begin
  if (exist('defaults.wws')) then
  begin
    assign(f,'defaults.wws');
    reset(f);
    seek(f,0);
    read(f,defaults);
    close(f);
  end
  else
  begin
    writeln;
    defaults.defcolors[0]:=7;
    defaults.defcolors[1]:=11;
    defaults.defcolors[2]:=14;
    defaults.defcolors[3]:=5;
    defaults.defcolors[4]:=31;
    defaults.defcolors[5]:=2;
    defaults.defcolors[6]:=140;
    defaults.defcolors[7]:=9;
    defaults.defcolors[8]:=1;
    defaults.defcolors[9]:=15;
    defaults.defmono[0]:=1;
    defaults.defmono[1]:=9;
    defaults.defmono[2]:=9;
    defaults.defmono[3]:=9;
    defaults.defmono[4]:=16;
    defaults.defmono[5]:=9;
    defaults.defmono[6]:=137;
    defaults.defmono[7]:=1;
    defaults.defmono[8]:=1;
    defaults.defmono[9]:=9;
    defaults.defmode:=True;
  end;
end;

procedure view(filename:fname);
var lastcolor:byte;
    line:string;
    temp:string[2];
    c1,c2,c:byte;
    code:integer;
    start:byte;
    textlen:byte;
begin
  assign(f,filename);
  reset(f);
  textattr:=15;
  clrscr;
  lastcolor:=0;
  c:=0;
  while(not eof(f)) do
  begin
    inc(c);
    lastcolor:=0;
    readln(f,line);
    if(line[1]<>#2)then
    begin
      c2:=1;
      start:=1;
    end
    else
    begin
      textlen:=0;
      start:=2;
      for c1:=2 to length(line) do
        if (line[c1]<>CTRP)then
          inc(textlen)
        else
          inc(c1);
      c2:=((80-textlen)div 2);
    end;
    for c1:=start to length(line) do
    begin
      if (line[c1]<>CTRP) then
      begin
        gotoxy(c2,c);
        if(defaults.defmode)then
          textattr:=defaults.defcolors[lastcolor]
        else
          textattr:=defaults.defmono[lastcolor];
        write(line[c1]);
        inc(c2);
      end
      else
      begin
        inc(c1);
        temp:=line[c1];
        val(temp,lastcolor,code);
      end;
    end;
  end;
end;

begin
  loaddefaults;
  esc:=false;
  If (paramcount>0) then
    mask:=paramstr(1)
  else
  begin
    textattr:=15;
    clrscr;
    showdir('*.*');
    writeln;
    write('Enter filename (or mask): ');
    readln(mask);
  end;
  if(exist(mask))then
  begin
    fsplit(mask,dir,name,ext);
    findfirst(mask,anyfile,dirstuff);
    while((doserror=0)and(esc=false))do
    begin
      textattr:=15;
      clrscr;
      if ((dirstuff.attr<>readonly) and
          (dirstuff.attr<>sysfile) and
          (dirstuff.attr<>hidden) and
          (dirstuff.attr<>volumeid) and
          (dirstuff.attr<>directory)) then
        view(dir+dirstuff.name);
      gotoxy(1,25);
      textattr:=15;
      Write('Press any key ');
      if (pos('?',mask)+pos('*',mask)<>0)then
        write('for next file matching ''',mask,''' or ESC to quit');
      write('...');
      Dummy:=ReadKey;
      if ord(dummy)=0 then
        dummy:=Readkey
      else
      begin
        if(ord(dummy)=27)then
          esc:=true;
      end;
      findnext(dirstuff);
    end;
  end
  else
  begin
    writeln;
    textattr:=15;
    write('The file was ');
    textcolor(red+blink);
    write('NOT');
    textcolor(white);
    writeln(' found.');
    writeln;
  end;
end.
