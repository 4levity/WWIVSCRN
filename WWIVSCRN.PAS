{$M $4000,0,0 }   { 16K stack, no heap }

{
WWIV Screenedit by Ivan Cooper
}

uses crt,dos;
Type ScreenType = Array [1..80,1..23] of char;
     CMap     = Array [1..80,1..23] of byte;
     CSetup   = Array [0..9] of byte;
     fname    = string[35];
     defsetup = record
                  autofile  : fname;
                  defcolors : csetup;
                  defmono   : csetup;
                  SFX       : boolean;
                  defmode   : boolean;
                end;

Var  Done     : Boolean;
     c        : char;
     ch       : char;
     c1,c2    : Byte;
     x,y      : Byte;
     topx,topy: byte;
     botx,boty: byte;
     code     : integer;
     CurColor : byte;
     CurSet   : byte;
     Filename : fname;
     Filen    : fname;
     Viewfile : fname;
     F        : Text;
     Count    : Byte;
     Line     : String;
     Screen   : ScreenType;
     Colors   : CMap;
     Colorset : CSetup;
     Monoset  : CSetup;
     rotate   : byte;
     Insert   : Boolean;
     Mask     : Pathstr;
     Rulerpos : byte;
     defaults : defsetup;
     color    : boolean;
     colorbak : boolean;
     msg      : String;
     saved    : Boolean;
     menunum  : integer;
     s        : string;
     ok       : boolean;
     cancel   : boolean;
     curcbak  : byte;

Const
     CTRP     : Char = #3;
     Vernum   : Real = 3.2;
     Fsets    : Array [1..10] of String[10] = (
'⁄ø¿Ÿƒ≥√¥¡¬',
'…ª»ºÕ∫Ãπ À',
'’∏‘æÕ≥∆µœ—',
'÷∑”Ωƒ∫«∂–“',
'≈Œÿ◊ËÈõúôÔ',
'∞±≤€ﬂ‹›ﬁ˛˙',
'Ï˘®≠Îû‚Ìö',
'ÓÁÊÂüëÄá‡ò',
'ÆØÚÛ©™˝ˆ´¨',
'„ÒÙıÍù‰¯˚¸');


procedure badkey;
begin
  if(defaults.sfx)then
  begin
    sound(500);
    delay(10);
    nosound;
  end;
end;

Procedure Pause;
var dummy:char;
Begin
  Write('Press any key...');
  Dummy:=ReadKey;
  if ord(dummy)=0 then dummy:=Readkey;
  GotoXY (WhereX-16,Wherey);
  ClrEOL;
end;

Procedure Dir(Mask:PathStr);
Var dirstuff : searchrec;
Begin
  Count:=0;
  If mask='' then mask := '*.*';
  writeln('Directory of ',mask);
  FindFirst (Mask, Anyfile, DirStuff);
  While doserror = 0 do
  Begin
    if((dirstuff.attr<>readonly)and(dirstuff.attr<>hidden)and
       (dirstuff.attr<>sysfile) and(dirstuff.attr<>volumeid)and
       (dirstuff.attr<>directory))then
    begin
      Write(DirStuff.Name:20);
      Inc(Count);
    end;
    FindNext (DirStuff);
    If Count=80 then
    Begin
      Pause;
      Count:=0;
    end;
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
  Exist:=((doserror=0)and(s.attr<>readonly)and(s.attr<>hidden)and
         (s.attr<>sysfile)and(s.attr<>volumeid)and(s.attr<>directory));
end;

procedure hilite(s:string);
var c:byte;
begin
  for c:=1 to length(s) do
  begin
    if(s[c]='^')then
    begin
      inc(c);
      highvideo;
      write(s[c]);
    end
    else
    begin
      lowvideo;
      write(s[c]);
    end;
  end;
end;

procedure initScreen;
var c1,c2:byte;
begin
  for c1:=1 to 80 do
    for c2:=1 to 23 do
      begin
        Screen[c1,c2]:=' ';
        colors[c1,c2]:=curcolor;
      end;
  filename:='NONAME.ANS';
  saved:=true;
end;

procedure insertline(y:byte);
var c1,c2:byte;
begin
for c1:=23 downto y do
  for c2:=1 to 80 do
  begin
    if(c1=y)then
    begin
      Screen[c2,c1]:=' ';
      colors[c2,c1]:=curcolor;
    end
    else
    begin
      Screen[c2,c1]:=Screen[c2,c1-1];
      colors[c2,c1]:=colors[c2,c1-1];
    end;
  end;
end;

procedure initcolors;
begin
  monoset[0]:=defaults.defmono[0];
  monoset[1]:=defaults.defmono[1];
  monoset[2]:=defaults.defmono[2];
  monoset[3]:=defaults.defmono[3];
  monoset[4]:=defaults.defmono[4];
  monoset[5]:=defaults.defmono[5];
  monoset[6]:=defaults.defmono[6];
  monoset[7]:=defaults.defmono[7];
  monoset[8]:=defaults.defmono[8];
  monoset[9]:=defaults.defmono[9];
  colorset[0]:=defaults.defcolors[0];
  colorset[1]:=defaults.defcolors[1];
  colorset[2]:=defaults.defcolors[2];
  colorset[3]:=defaults.defcolors[3];
  colorset[4]:=defaults.defcolors[4];
  colorset[5]:=defaults.defcolors[5];
  colorset[6]:=defaults.defcolors[6];
  colorset[7]:=defaults.defcolors[7];
  colorset[8]:=defaults.defcolors[8];
  colorset[9]:=defaults.defcolors[9];
  color:=defaults.defmode;
end;

procedure savedefaults;
var f:file of defsetup;
begin
  assign(f,'defaults.wws');
  rewrite(f);
  seek(f,0);
  write(f,defaults);
  close(f);
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
    writeln('Defaults file does not exist. Creating one..');
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
    defaults.autofile:='';
    defaults.defmode:=True;
    defaults.sfx:=true;
    savedefaults;
  end;
end;

procedure botcycle;
var s:string;
begin
  s:='WWIV Screenedit!';
  if(defaults.sfx)then
  begin
    while not(keypressed)do
    begin
      gotoxy(1,24);
      for count:=1 to 16 do
      begin
        textbackground(black);
        if(rotate+count-1>15)then
          textcolor((rotate+count-1)-16)
        else
          textcolor(rotate+count-1);
        write(s[count]);
      end;
      if (rotate>0) then dec(rotate) else rotate:=15;
      gotoxy(x,y);
      if(color)then
        textattr:=colorset[curcolor]
      else
        textattr:=monoset[curcolor];
      delay(20);
    end;
  end
  else
  begin
    gotoxy(1,24);
    textattr:=7;
    write(s);
  end;
  if(color)then
    textattr:=colorset[curcolor]
  else
    textattr:=monoset[curcolor];
  gotoxy(x,y);
end;

procedure newcolor;
begin
  gotoxy(10,25);
  if(color)then
    textattr:=colorset[curcolor]
  else
    textattr:=monoset[curcolor];
  if(curcolor<8)then
    write('Color ',curcolor)
  else
    write('Extra ',curcolor);
end;

procedure insmode;
begin
  gotoxy(17,25);
  textbackground(black);
  if(insert)then
  begin
    textcolor(yellow);
    write(' Ins');
  end
  else
  begin
    textcolor(lightgreen);
    write(' Ovr');
  end;
end;

procedure newset;
var c:byte;
begin
  gotoxy(21,25);
  textcolor(white);
  write('  Set',curset:2,':');
  textbackground(blue);
  for c:=1 to 10 do
    write(' F',c,'=',fsets[curset,c]);
  textattr:=7;
  clreol;
end;

procedure newmode;
begin
  gotoxy(17,24);
  if(color)then
  begin
    textattr:=14;
    write('  Color  ');
  end
  else
  begin
    textattr:=9;
    write('  Mono   ');
  end;
end;

procedure redoall;
begin
  newmode;
  newcolor;
  insmode;
  newset;
end;

procedure bottomscreen;
var name:namestr;
    ext:extstr;
    dir:dirstr;
begin
  gotoxy(1,25);
  textattr:=15;
  write('(',x:2,',',y:2,')  ');
  gotoxy(26,24);
  write(msg);
  clreol;
  gotoxy(62,24);
  textattr:=7;
  fsplit(filename,dir,name,ext);
  write('File: ',name+ext:12);
  clreol;
end;

procedure putline(lnum:byte);
var c1:byte;
begin
  gotoxy(1,lnum);
  for c1:=1 to 79 do
  begin
    if(color)then
      textattr:=colorset[colors[c1,lnum]]
    else
      textattr:=monoset[colors[c1,lnum]];
    write(Screen[c1,lnum]);
  end;
end;

procedure putcol(cnum:byte);
var c1:byte;
begin
  for c1:=1 to 23 do
  begin
    gotoxy(cnum,c1);
    if(color)then
      textattr:=colorset[colors[cnum,c1]]
    else
      textattr:=monoset[colors[cnum,c1]];
    write(Screen[cnum,c1]);
  end;
end;

procedure printScreen;
var c1:byte;
begin
  for c1:=1 to 23 do
  begin
    putline(c1);
    textattr:=15;
    gotoxy(80,c1);
    write(' ');
  end;
end;

procedure revline(y,topx,x:byte);
var c1:byte;
begin
  gotoxy(topx,y);
  for c1:=topx to x do
  begin
    if(color)then
    begin
      if(not(colorset[colors[c1,y]] in [112..127]))then
        textattr:=112
      else
        textattr:=7;
    end
    else
    begin
      if(monoset[colors[c1,y]]<>16)then
        textattr:=16
      else
        textattr:=1;
    end;
    write(Screen[c1,y]);
  end;
end;

procedure revcol(x,topy,y:byte);
var c1:byte;
begin
  for c1:=topy to y do
  begin
    if(color)then
    begin
      if(not(colorset[colors[x,c1]] in [112..127]))then
        textattr:=112
      else
        textattr:=7;
    end
    else
    begin
      if(monoset[colors[x,c1]]<>16)then
        textattr:=16
      else
        textattr:=1;
    end;
    gotoxy(x,c1);
    write(Screen[x,c1]);
  end;
end;

procedure putblock(block:screentype;bcolor:cmap;x,y,ux,uy,bx,by:byte);
var c1,c2:byte;
begin
  for c2:=uy to by do
  begin
    gotoxy(x,y+(c2-uy));
    for c1:=ux to bx do
    begin
      if(color)then
      begin
        if(colorset[bcolor[c1,c2]] in [112..127])then
          textattr:=7
        else
          textattr:=112;
      end
      else
      begin
        if(monoset[bcolor[c1,c2]]=16)then
          textattr:=1
        else
          textattr:=16;
      end;
      write(block[c1,c2]);
    end;
  end;
end;

procedure getcpos(var cancel:boolean;minx,miny:byte);
var ch:char;
    done:boolean;
begin
  done:=false;
  cancel:=false;
  repeat
    textattr:=15;
    gotoxy(1,25);
    write('(',x:2,',',y:2,') Press ESC to cancel');
    botcycle;
    ch:=readkey;
    if (ch=#0)then
    begin
      ch:=readkey;
      case ord(ch) of
        72: if(y>miny)then  y:=y-1;  {Up}
        80: if(y<23)then y:=y+1;  {Down}
        75: if(x>minx)then  x:=x-1;  {Left}
        77: if(x<79)then x:=x+1;  {Right}
        71: x:=minx;              {Home}
        79: x:=79;                {End}
        73: y:=miny;              {PgUp}
        81: y:=23;                {PgDn}
        119: begin                {C-Home}
               x:=minx;
               y:=miny;
             end;
        117: begin                {C-End}
               x:=minx;
               y:=23;
             end;
        132: begin                {C-PgUp}
               x:=79;
               y:=miny;
             end;
        118: begin                {C-PgDn}
               x:=79;
               y:=23;
             end;
        else badkey;
      end;
    end
    else
    begin
      case ch of
        ' ': begin
               done:=true;
             end;
        #13: begin
               x:=minx;
               if(y<23)then
                 y:=y+1;
             end;
        #27: cancel:=true;
        else badkey;
      end;
    end;
  until ((cancel) or (done));
end;

function yn:boolean;
var ch:char;yes:boolean;okkey:boolean;
begin
  okkey:=false;
  repeat
    ch:=upcase(readkey);
    if(ch=#0)then
      ch:=readkey
    else
    begin
      if(ch='Y')then
      begin
        write('Yes');
        yes:=true;
        okkey:=true;
      end
      else if(ch='N')then
      begin
        write('No');
        yes:=false;
        okkey:=true;
      end;
    end;
  until okkey;
  yn:=yes;
end;

procedure altercolors(var colorset,monoset:csetup);
begin
  repeat
    textattr:=15;
    clrscr;
    for c1:=0 to 9 do
    begin
      if(color)then
        textattr:=colorset[c1]
      else
        textattr:=monoset[c1];
      writeln('Color #',c1);
    end;
    writeln;
    textattr:=15;
    write('Change which (0-9, Q=Quit) ? ');
    repeat
    ch:=upcase(readkey);
    until (ch in ['0'..'9','Q']);
    if(ch<>'Q')then
    begin
      textattr:=15;
      clrscr;
      c2:=ord(ch)-ord('0');
      if(color)then
      begin
        writeln('Defining color ',c2);
        textattr:=colorset[c2];
        for c1:=0 to 9 do
        begin
          textbackground(c1);
          writeln('Background #',c1);
        end;
        textbackground(black);
        writeln;
        textattr:=15;
        write('Background (0-7) ? ');
        repeat
          ch:=readkey;
        until (ch in ['0'..'7']);
        colorset[c2]:=(ord(ch)-ord('0'))*16;
        textattr:=15;
        clrscr;
        writeln('Defining color ',c2);
        textattr:=colorset[c2];
        for c1:=0 to 15 do
        begin
          textcolor(c1);
          if(c1<10)then
            writeln('Foreground ',c1)
          else
            writeln('Foreground ',chr(ord('A')+(c1-10)));
        end;
        writeln;
        textattr:=15;
        writeln('Foreground (0-F) ? ');
        repeat
          ch:=upcase(readkey);
        until (ch in ['0'..'9','A'..'F']);
        if(ch in ['0'..'9'])then
          inc(colorset[c2],ord(ch)-ord('0'))
        else
          inc(colorset[c2],ord(ch)-ord('A')+10);
      end
      else
      begin
        textattr:=monoset[c2];
        writeln('Defining color ',c2);
        textattr:=15;
        monoset[c2]:=1;
        writeln;
        write('Intense? ');
        if(yn)then
          inc(monoset[c2],8);
        writeln;
        write('Inverse? ');
        if(yn)then
          inc(monoset[c2],16);
        writeln;
        write('Blinking? ');
        if(yn)then
          inc(monoset[c2],128);
      end;
    end;
  until (ch='Q');
end;

procedure filescreen(var f:text;ftype:byte;botline:byte);
var lastcolor:byte;
    c1,c2:byte;
    line:string;
    endline:byte;
    found:boolean;
begin
  for c1:=1 to botline do
  begin
    lastcolor:=0;
    endline:=79;
    found:=false;
    repeat
      if(color)then
      begin
        if ((Screen[endline,c1]=' ') and (colorset[colors[endline,c1]]<16))then
          dec(endline)
        else
          found:=true;
      end
      else
      begin
        if((screen[endline,c1]=' ') and (monoset[colors[endline,c1]]<16))then
          dec(endline)
        else
          found:=true;
      end;
    until ((found) or (endline=1));
    for c2:=1 to endline do
    begin
      if((colors[c2,c1]<>lastcolor)and(ftype<>0))then
      begin
        write(f,CTRP,colors[c2,c1]);
        lastcolor:=colors[c2,c1];
      end;
      write(f,Screen[c2,c1]);
    end;
    writeln(f);
  end;
end;

procedure dirmsg(filename:fname);
var mnum:string[2];
    code:integer;
    nfound:integer;
begin
  textattr:=15;
  clrscr;
  writeln('Menus contained in menufile: ',filename);
  assign(f,filename);
  reset(f);
  nfound:=0;
  while(not(eof(f)))do
  begin
    readln(f,line);
    if((line[1]='`')and(line[4]='='))then
    begin
      inc(nfound);
      if(line[3]='=')then
        mnum:=line[2]
      else
        mnum:=line[2]+line[3];

      writeln(' -- MENU',mnum,'.ANS');
    end;
  end;
  close(f);
  if(nfound>0)then
    writeln(nfound,' menus found..')
  else
    writeln('ERROR! No menus found.');
  pause;
end;

procedure view(filename:fname);
var lastcolor:byte;
    line:string;
    temp:string[2];
    c1,c2:byte;
    code:integer;
    start:byte;
    textlen:byte;
    sx,sy:byte;
begin
  assign(f,filename);
  reset(f);
  textattr:=15;
  clrscr;
  lastcolor:=0;
  while(not eof(f)) do
  begin
    writeln;
    sx:=wherex;
    sy:=wherey;
    gotoxy(1,1);
    textattr:=15;
    clreol;
    write('File: '+filename:79);
    gotoxy(sx,sy);
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
        if(color)then
          textattr:=colorset[lastcolor]
        else
          textattr:=monoset[lastcolor];
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
  gotoxy(1,1);
  textattr:=15;
  pause;
  close(f);
end;

procedure savemsg(filename:fname;menunum:integer;botline:byte);
var lastcolor:byte;
    endline:byte;
    found:boolean;
    f1:file;
    f2:text;
    line:string;
    temp:string[2];
    c1,c2,c:byte;
    code:integer;
    start:byte;
    textlen:byte;
    mfound:integer;
    endmenu:boolean;
    menuin:boolean;
begin
  assign(f,filename);
  reset(f);
  assign(f2,'MENUTEMP.$$$');
  rewrite(f2);
  c:=0;
  ok:=true;
  found:=false;
  menuin:=false;
  while((not (eof(f))) and (not(found)) and(ok))do
  begin
    inc(c);
    readln(f,line);
    if((line[1]='`')and(line[4]='='))then
    begin
      if(line[3]='=')then
        temp:=line[2]
      else
        temp:=line[2]+line[3];
      val(temp,mfound,code);
      if(code=0)then
      begin
        if(mfound=menunum)then
        begin
          found:=true;
          menuin:=true;
        end
        else if(mfound>menunum)then
        begin
          menuin:=false;
          found:=true;
        end
        else
          writeln(f2,line);
      end
      else
        ok:=false;
    end
    else
      writeln(f2,line);
  end;
  if(eof(f))then
  begin
    close(f2);
    close(f);
    assign(f1,'MENUTEMP.$$$');
    erase(f1);
    assign(f,filename);
    append(f);
    writeln(f,'`',menunum,'=======================================================WWIV=Screenedit=Save=');
    filescreen(f,1,botline);
    close(f);
  end
  else if(not menuin)then
  begin
    writeln(f2,'`',menunum,'=======================================================WWIV=Screenedit=Save=');
    filescreen(f2,1,botline);
    writeln(f2,line);
    while(not eof(f))do
    begin
      readln(f,line);
      writeln(f2,line);
    end;
    close(f);
    close(f2);
    assign(f1,filename);
    erase(f1);
    assign(f1,'MENUTEMP.$$$');
    rename(f1,filename);
  end
  else
  begin
    found:=false;
    while(not(found)and not(eof(f)))do
    begin
      readln(f,line);
      if((line[1]='`')and(line[4]='='))then
        found:=true;
    end;
    writeln(f2,'`',menunum,'=======================================================WWIV=Screenedit=Save=');
    filescreen(f2,1,botline);
    if(not eof(f))then
    begin
      writeln(f2,line);
      while(not eof(f))do
      begin
        readln(f,line);
        writeln(f2,line);
      end;
    end;
    close(f);
    close(f2);
    assign(f1,filename);
    erase(f1);
    assign(f1,'MENUTEMP.$$$');
    rename(f1,filename);
    close(f1);
  end;
end;

procedure loadmsg(filename:fname;menunum:integer;var ok:boolean);
var line:string;
    lastcolor:byte;
    endline:byte;
    found:boolean;
    temp:string[2];
    c1,c2,c:byte;
    code:integer;
    start:byte;
    textlen:byte;
    mfound:integer;
    lineon:integer;
    endmenu:boolean;
begin
  assign(f,filename);
  reset(f);
  c:=0;
  ok:=true;
  found:=false;
  while((not (eof(f))) and (not(found)) and(ok))do
  begin
    inc(c);
    readln(f,line);
    if((line[1]='`')and(line[4]='='))then
    begin
      if(line[3]='=')then
        temp:=line[2]
      else
        temp:=line[2]+line[3];
      val(temp,mfound,code);
      if(code=0)then
      begin
        if(mfound=menunum)then
        begin
          found:=true;
          lineon:=c;
        end;
      end
      else
        ok:=false;
    end
  end;
  if(eof(f))then
    ok:=false;
  close(f);
  if(not(found))then
    ok:=false;
  if(ok)then
  begin
    assign(f,filename);
    reset(f);
    for c2:=1 to lineon do
      readln(f,line);
    lastcolor:=0;
    c:=0;
    endmenu:=false;
    while((not(eof(f))) and (not(endmenu))) do
    begin
      inc(c);
      lastcolor:=0;
      readln(f,line);
      if((line[1]<>'`') and (line[4]<>'='))then
      begin
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
            if(c2<80)and(c<24)then
            begin
              Screen[c2,c]:=line[c1];
              colors[c2,c]:=lastcolor;
              inc(c2);
            end;
          end
          else
          begin
            inc(c1);
            temp:=line[c1]+'';
            val(temp,lastcolor,code);
          end;
        end;
      end
      else
        endmenu:=true;
    end;
    close(f);
  end;
end;

procedure load(filename:fname);
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
        if(c2<80)and(c<24)then
        begin
          Screen[c2,c]:=line[c1];
          colors[c2,c]:=lastcolor;
          inc(c2);
        end;
      end
      else
      begin
        inc(c1);
        temp:=line[c1]+'';
        val(temp,lastcolor,code);
      end;
    end;
  end;
  close(f);
  saved:=true;
end;

procedure save(filename:fname;ftype:byte;botline:byte);
begin
  assign(f,filename);
  rewrite(f);
  filescreen(f,ftype,botline);
  close(f);
  saved:=true;
end;

Procedure Vline(x:byte;ch:char);
var count:byte;
begin
  For count := 1 to 13 do
  begin
    gotoXY(x,(2*count+(x mod 2))-1);
    write(ch);
  end;
end;

Procedure Hline(y:byte;ch:char);
var count:byte;
begin
  For count := 1 to 40 do
  begin
    gotoXY(2*count+abs(y mod 2-1)-1,y);
    write(ch);
  end;
end;

procedure fseffect(efnum:byte);
var x,y:byte;
    c3:byte;
begin
  case efnum of
    0: begin
         textattr:=15;
         For y := 1 to 25 do
         Begin
         Hline(y,'-');
         delay(5);
         hline(y,' ');
         end;
         for x := 1 to 80 do
         begin
         vline(x,'≥');
         delay(5);
         vline(x,' ');
         end;
         clrscr;
         textattr:=15;
         gotoxy(1,24);
       end;
    1: begin
         for c1:=1 to 12 do
         begin
           textcolor(white);
           textbackground(red);
           gotoxy(1,c1);
           clreol;
           gotoxy(1,26-c1);
           clreol;
           for c2:=1+c1 to 25-c1 do
           begin
             gotoxy(c1*3-3,c2);
             write('   ');
             gotoxy(80-c1*3,c2);
             write('   ');
           end;
           delay(70);
         end;
         gotoxy(36,13);
         textcolor(lightred);
         write('Goodbye!');
         textattr:=15;
         gotoxy(1,24);
       end;
    2: begin
         textattr:=15;
         gotoxy(1,24);
         clreol;
         gotoxy(1,25);
         clreol;
         for c1:=1 to 23 do
         begin
           gotoxy(1,c1);
           for c2:=1 to 79 do
           begin
             if(color)then
               textattr:=colorset[colors[c2,c1]]
             else
               textattr:=monoset[colors[c2,c1]];
             write('˛');
           end;
         end;
         textattr:=15;
         gotoxy(1,24);
       end;
    3: begin
         textattr:=15;
         gotoxy(1,1);
         for c3:=1 to 24 do
           write('∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞');
         gotoxy(1,1);
         delay(150);
         for c3:=1 to 24 do
           write('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±');
         gotoxy(1,1);
         delay(150);
         for c3:=1 to 24 do
           write('≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤≤');
         gotoxy(1,1);
         delay(150);
         for c3:=1 to 24 do
           write('€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€');
         gotoxy(1,1);
         delay(150);
         for c3:=1 to 25 do
           write('                                                                                ');
       end;
    4: begin
         textattr:=15;
         for c1:=1 to 79 do
           for c2:=1 to 25 do
           begin
             if((c2 mod 2)=0)then
               gotoxy(c1,c2)
             else
               gotoxy(80-c1,c2);
             write('-');
             delay(1);
           end;
         for c1:=1 to 79 do
           for c2:=1 to 25 do
           begin
             if((c2 mod 2)=0)then
               gotoxy(c1,c2)
             else
               gotoxy(80-c1,c2);
             write(' ');
             delay(1);
           end;
         gotoxy(1,24);
       end;
  end;
end;

{$I WWIVBLCK.PAS}

begin
  randomize;
  saved:=true;
  str(vernum:0:1,s);
  msg:='Version '+s+' - Press ALT-H for help';
  loaddefaults;
  rotate:=15;
  Insert:=False;
  Done:=False;
  x:=1;
  y:=1;
  curcolor:=0;
  InitScreen;
  initcolors;
  curset:=1;
  printScreen;
  if (defaults.autofile<>'')then
  begin
    if (exist(defaults.autofile))then
    begin
      load(defaults.autofile);
      if(not ok)then
      begin
        writeln('Invalid autofile!');
        pause;
      end
      else
      begin
        filename:=defaults.autofile;
      end;
    end
    else
    begin
      writeln('Can''t find AUTOFILE: ',defaults.autofile);
      pause;
    end;
  end;
  redoall;
  repeat
    gotoxy(x,y);
    if(color)then
      textattr:=colorset[curcolor]
    else
      textattr:=monoset[curcolor];
    bottomscreen;
    botcycle;
    c:=readkey;
    case c of
      #0: begin
            c:=readkey;
            case ord(c) of
              59..68: begin   { F1 - F10 }
                        saved:=false;
                        if(insert=false)then
                        begin
                          Screen[x,y]:=fsets[curset][ord(c)-58];
                          colors[x,y]:=curcolor;
                          if(color)then
                            textattr:=colorset[colors[x,y]]
                          else
                            textattr:=monoset[colors[x,y]];
                          write(Screen[x,y]);
                        end
                        else
                        begin
                          for c1:=78 downto x do
                          begin
                            Screen[c1+1,y]:=Screen[c1,y];
                            colors[c1+1,y]:=colors[c1,y];
                          end;
                          Screen[x,y]:=fsets[curset][ord(c)-58];
                          colors[x,y]:=curcolor;
                          putline(y);
                        end;
                        if(x<79)then inc(x);
                        msg:='';
                      end;
              104..113: begin { ALT-F1 - ALT-F10 }
                          curset:=ord(c)-103;
                          str(curset,s);
                          msg:='Now using set '+s;
                          newset;
                        end;
              30: begin       { ALT - A }
                    textattr:=15;
                    clrscr;
                    for count:=0 to 9 do
                    begin
                      if(color)then
                        textattr:=colorset[count]
                      else
                        textattr:=monoset[count];
                      writeln('Color #',count);
                    end;
                    writeln;
                    textattr:=15;
                    write('Use which (0-9, Q=Quit) ? ');
                    repeat
                      ch:=upcase(readkey);
                    until (ch in ['0'..'9','Q']);
                    if (ch in ['0'..'9']) then curcolor:=ord(ch)-ord('0');
                    printScreen;
                    str(curcolor,s);
                    msg:='Color changed to'+s;
                    redoall;
                  end;
              48: begin       { Alt - B }
                    blockop(cancel);
                    printScreen;
                    redoall;
                    if(not cancel)then
                    begin
                      msg:='Block operation done';
                      saved:=false;
                    end
                    else
                      msg:='Aborted';
                  end;
              46: begin       { ALT - C }
                    if(not saved)then
                    begin
                      gotoxy(1,25);
                      textattr:=15;
                      clreol;
                      gotoxy(1,24);
                      clreol;
                      write('Screen not saved! Clear anyway? ');
                      if(yn)then
                      begin
                        initScreen;
                        printScreen;
                        msg:='Screen cleared';
                      end;
                    end
                    else
                    begin
                      initscreen;
                      printscreen;
                      msg:='Screen cleared';
                    end;
                    redoall;
                  end;
              32: begin       { ALT - D }
                    altercolors(colorset,monoset);
                    printScreen;
                    redoall;
                    msg:='';
                  end;
              18: begin       { Alt - E }
                    repeat
                      textattr:=15;
                      clrscr;
                      writeln('1. File to autoload: ',defaults.autofile);
                      writeln('2. Default color set...');
                      writeln('3. Default mono set...');
                      write('4. Effects: ');
                      if(defaults.sfx)then
                        writeln('On')
                      else
                        writeln('Off');
                      write('5. Default mode: ');
                      if(defaults.defmode)then
                        writeln('Color')
                      else
                        writeln('Mono');
                      writeln('Change 1-5, Q to quit .. ');
                      repeat
                        ch:=upcase(readkey);
                      until (ch in ['1'..'5','Q']);
                      if (ch='1')then
                      begin
                        writeln;
                        write('Enter name of file to autoload(ENTER for none): ');
                        readln(line);
                        if (okname(line)) then
                          defaults.autofile:=line;
                      end
                      else if (ch='2')then
                      begin
                        colorbak:=color;
                        color:=true;
                        altercolors(defaults.defcolors,defaults.defmono);
                        color:=colorbak;
                      end
                      else if (ch='3')then
                      begin
                        colorbak:=color;
                        color:=false;
                        altercolors(defaults.defcolors,defaults.defmono);
                        color:=colorbak;
                      end
                      else if (ch='4')then
                      begin
                        writeln;
                        write('Special effects on? ');
                        if(yn)then
                          defaults.sfx:=true
                        else
                          defaults.sfx:=false;
                      end
                      else if (ch='5')then
                      begin
                        writeln;
                        write('Start in COLOR mode? ');
                        if(yn)then
                          defaults.defmode:=true
                        else
                          defaults.defmode:=false;
                      end;
                    until (ch='Q');
                    writeln;
                    writeln('Saving defaults..');
                    savedefaults;
                    printScreen;
                    redoall;
                    msg:='Defaults file saved';
                  end;
              33: begin       { ALT - F }
                    textattr:=15;
                    clrscr;
                    writeln('             Extended Character Set Function Key Sets');
                    writeln;
                    writeln;
                    writeln('                       F1  F2  F3  F4  F5  F6  F7  F8  F9  F10');
                    writeln('                  Set');
                    writeln('              ⁄');
                    writeln('              ≥');
                    writeln('              ≥');
                    writeln('              ≥');
                    writeln('ALT (F1-F10) ƒ¥');
                    writeln('              ≥');
                    writeln('              ≥');
                    writeln('              ≥');
                    writeln('              ≥');
                    writeln('              ¿');
                    for c1:=1 to 10 do
                      begin
                      gotoxy(20,5+c1);
                      write(c1);
                      for c2:=1 to 10 do
                        begin
                          gotoxy(21+(c2*4),5+c1);
                          write(fsets[c1][c2]);
                        end;
                      end;
                    gotoxy(1,24);
                    pause;
                    printScreen;
                    redoall;
                    msg:='';
                  end;
              35: begin       { ALT - H }
                    textattr:=15;
                    clrscr;
                    textbackground(blue);
                    writeln('  WWIV Screenedit version ',vernum:0:1,' help screen  ');
                    textattr:=15;
                    writeln;
                    writeln('Here are the commands:');
                    writeln;
                    writeln('Alt-A  Select Color                  Alt-M  Toggle Color/Mono');
                    writeln('Alt-B  Block Operations              Alt-N  Ruler');
                    writeln('Alt-C  Clear Screen                  Alt-O  Original Colors');
                    writeln('Alt-D  Alter Color Set               Alt-R  Draw Rectangle');
                    writeln('Alt-E  Edit Setup                    Alt-S  Save File');
                    writeln('Alt-F  Function Key Sets Available   Alt-T  Center Text');
                    writeln('Alt-H  Help                          Alt-U  Use Colors Under Cursor');
                    writeln('Alt-I  Insert Line                   Alt-V  View File (Not Load)');
                    writeln('Alt-J  Jump to DOS Temporarily       Alt-W  "Directory" of a menufile');
                    writeln('Alt-K  Save menu to menufile         Alt-X  Exit WWIV Screenedit');
                    writeln('Alt-L  Load A File                   Alt-Y  Delete Current Line');
                    writeln('Alt F(1-10) Select FKey Set          Alt-Z  Load menu from Menufile');
                    writeln('Del - Delete char under cursor       Ins - Toggle insert mode');
                    writeln('Ctrl-Left - Down 1 color             Ctrl-Right - Up one color');
                    writeln;
                    writeln('The cursor is moved using the arrow keys. Also, the following keys can be used:');
                    writeln('Home       First column of line   PgUp       Top line in column');
                    writeln('End        Last column of line    PgDn       Bottom line in column');
                    writeln('Ctrl-Home  Upper left corner      Ctrl-PgUp  Upper right corner');
                    writeln('Ctrl-End   Lower left corner      Ctrl-PgDn  Lower right corner');
                    gotoxy(1,25);
                    pause;
                    printScreen;
                    redoall;
                    msg:='';
                  end;
              23: begin       { Alt - I }
                    insertline(y);
                    printScreen;
                    msg:='Line inserted';
                    saved:=false;
                  end;
              36: begin       { Alt - J }
                    textattr:=15;
                    clrscr;
                    writeln;
                    writeln('Type EXIT to return to WWIV Screenedit');
                    SwapVectors;
                    Exec(getenv('COMSPEC'),'');
                    SwapVectors;
                    if DosError <> 0 then
                      msg:='Unable to shell!'
                    else
                      msg:='';
                    pause;
                    printScreen;
                    redoall;
                  end;
              37: begin       { Alt - K }
                    textattr:=15;
                    gotoxy(1,25);
                    clreol;
                    write('Current filename: ',filename);
                    gotoxy(1,24);
                    clreol;
                    write('Enter name of menufile: ');
                    readln(filen);
                    if((okname(filen))and(filen<>'')and(exist(filen)))then
                    begin
                      gotoxy(1,24);
                      clreol;
                      write('Enter menu number: ');
                      readln(s);
                      val(s,menunum,code);
                      if(code=0)then
                      begin
                        if(diskfree(0)>5500)then
                        begin
                          str(menunum,s);
                          gotoxy(1,24);
                          clreol;
                          writeln('                 Move cursor to the bottom line to save and press space');
                          clreol;
                          getcpos(cancel,1,1);
                          if(not cancel)then
                          begin
                            filename:='MENU'+s+'.ANS';
                            savemsg(filen,menunum,y);
                            msg:='File saved';
                            saved:=true;
                          end
                          else
                            msg:='Cancelled';
                        end
                        else
                          msg:='Not enough free space to save file!';
                      end
                      else
                        msg:='Invalid number';
                    end
                    else
                      msg:='Bad filename';
                    redoall;
                  end;
              38: begin       { Alt - L }
                    if(not saved)then
                    begin
                      textattr:=15;
                      gotoxy(1,24);
                      clreol;
                      gotoxy(1,25);
                      clreol;
                      textattr:=cyan;
                      write('Current picture not saved! Continue? ');
                      if(yn)then
                        ok:=true
                      else
                        ok:=false;
                    end
                    else
                      ok:=true;
                    if(ok)then
                    begin
                      textattr:=15;
                      clrscr;
                      dir('*.*');
                      gotoxy(1,25);
                      write('File- ',filename);
                      gotoxy(1,24);
                      write('Enter filename: ');
                      readln(filen);
                      if ((filen<>'') and okname(filen) and exist(filen)) then
                      begin
                        initScreen;
                        filename:=filen;
                        load(filen);
                        msg:='File loaded';
                        saved:=true;
                      end
                      else
                        msg:='Bad filename';
                      printScreen;
                      redoall;
                    end;
                  end;
              50: begin       { Alt - M }
                    color:=not(color);
                    printscreen;
                    msg:='Mode changed';
                    newmode;
                  end;
              49: begin       { Alt - N }
                    gotoxy(1,24);
                    clreol;
                    writeln('                  Ruler mode-Esc to exit');
                    clreol;
                    write('Use up/down arrows to move ruler');
                    rulerpos:=1;
                    repeat
                      gotoxy(1,rulerpos);
                      textcolor(white);
                      textbackground(lightgray);
                      write('√ƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒƒ≈ƒƒƒ¥');
                      botcycle;
                      ch:=readkey;
                      if (ch=#0)then
                      begin
                        ch:=readkey;
                        case ord(ch) of
                          72: begin
                                if(rulerpos<>1)then
                                begin
                                  putline(rulerpos);
                                  dec(rulerpos);
                                end;
                              end;
                          80: begin
                                if(rulerpos<>23)then
                                begin
                                  putline(rulerpos);
                                  inc(rulerpos);
                                end;
                              end;
                        end;
                      end;
                    until (ch=#27);
                    putline(rulerpos);
                    msg:='';
                    redoall;
                  end;
              24: begin       { Alt - O }
                    initcolors;
                    newcolor;
                    msg:='Using default colors';
                  end;
              19: begin       { ALT - R }
                    textattr:=15;
                    gotoxy(1,24);
                    clreol;
                    writeln('                  Position cursor at top left corner, and press space');
                    clreol;
                    getcpos(cancel,1,1);
                    if(not cancel)then
                    begin
                      textattr:=15;
                      gotoxy(1,24);
                      topx:=x;
                      topy:=y;
                      writeln('                  Position cursor at bottom left corner, and press space');
                      clreol;
                      write('         Top: (',topx:2,',',topy,')');
                      gotoxy(topx,topy);
                      textcolor(lightred);
                      textbackground(red);
                      write(screen[topx,topy]);
                      getcpos(cancel,topx,topy);
                      if(not cancel)then
                      begin
                        msg:='Rectangle added';
                        saved:=false;
                        botx:=x;
                        boty:=y;
                        for c1:=topx to botx do
                          if(curset<5)then
                          begin
                            Screen[c1,topy]:=fsets[curset][5];
                            Screen[c1,boty]:=fsets[curset][5];
                            colors[c1,topy]:=curcolor;
                            colors[c1,boty]:=curcolor;
                          end
                          else
                          begin
                            Screen[c1,topy]:=fsets[1][5];
                            Screen[c1,boty]:=fsets[1][5];
                            colors[c1,topy]:=curcolor;
                            colors[c1,boty]:=curcolor;
                          end;
                        for c1:=topy to boty do
                          if(curset<5)then
                          begin
                            Screen[topx,c1]:=fsets[curset][6];
                            Screen[botx,c1]:=fsets[curset][6];
                            colors[topx,c1]:=curcolor;
                            colors[botx,c1]:=curcolor;
                          end
                          else
                          begin
                            Screen[topx,c1]:=fsets[1][6];
                            Screen[botx,c1]:=fsets[1][6];
                            colors[topx,c1]:=curcolor;
                            colors[botx,c1]:=curcolor;
                          end;
                        if(curset<5)then
                        begin
                          Screen[topx,topy]:=fsets[curset][1];
                          Screen[botx,boty]:=fsets[curset][4];
                          Screen[topx,boty]:=fsets[curset][3];
                          Screen[botx,topy]:=fsets[curset][2];
                          colors[topx,topy]:=curcolor;
                          colors[botx,boty]:=curcolor;
                          colors[topx,boty]:=curcolor;
                          colors[botx,topy]:=curcolor;
                        end
                        else
                        begin
                          Screen[topx,topy]:=fsets[1][1];
                          Screen[botx,boty]:=fsets[1][4];
                          Screen[topx,boty]:=fsets[1][3];
                          Screen[botx,topy]:=fsets[1][2];
                          colors[topx,topy]:=curcolor;
                          colors[botx,boty]:=curcolor;
                          colors[topx,boty]:=curcolor;
                          colors[botx,topy]:=curcolor;
                        end;
                      end
                      else
                        msg:='Cancelled';
                    end
                    else
                      msg:='Cancelled';
                    printScreen;
                    redoall;
                  end;
              31: begin       { Alt - S }
                    textattr:=15;
                    gotoxy(1,25);
                    clreol;
                    write('Current filename: ',filename);
                    gotoxy(1,24);
                    clreol;
                    write('Enter filename: ');
                    readln(filen);
                    if((okname(filen))and(filen<>''))then
                    begin
                      clreol;
                      textattr:=lightgray;
                      hilite('Save in ^WWIV or ^Text (no color)? ');
                      ch:=upcase(readkey);
                      if (ch='W')then
                      begin
                        if(diskfree(0)>5500)then
                        begin
                          filename:=filen;
                          gotoxy(1,24);
                          clreol;
                          writeln('                  Move cursor to the bottom line to save and press space');
                          clreol;
                          getcpos(cancel,1,1);
                          if(not cancel)then
                          begin
                            save(filename,1,y);
                            msg:='File saved';
                            saved:=true;
                          end;
                        end
                        else
                          msg:='Not enough free space to save file!';
                      end
                      else if (ch='T')then
                      begin
                        filename:=filen;
                        gotoxy(1,24);
                        clreol;
                        write('                  Move cursor to the bottom line to save and press space');
                        x:=79;
                        getcpos(cancel,79,1);
                        if(not cancel)then
                        begin
                          save(filename,0,y);
                          msg:='File saved';
                          saved:=true;
                        end;
                      end;
                    end
                    else
                      msg:='Bad filename';
                    redoall;
                  end;
              20: begin       { Alt - T }
                    gotoxy(1,24);
                    textattr:=15;
                    clreol;
                    writeln('Enter the string to be centered..');
                    textattr:=31;
                    clreol;
                    readln(line);
                    if((length(line)<80) and (length(line)>0))then
                    begin
                      msg:='Line centered on page';
                      saved:=false;
                      for c1:=1 to length(line) do
                      begin
                        Screen[c1+((80-length(line)) div 2),y]:=line[c1];
                        colors[c1+((80-length(line)) div 2),y]:=curcolor;
                      end;
                      putline(y);
                    end
                    else
                      msg:='Invalid string length';
                    redoall;
                  end;
              22: begin       { Alt - U }
                    curcolor:=colors[x,y];
                    str(curcolor,s);
                    msg:='Using color '+s;
                    newcolor;
                  end;
              47: begin       { Alt - V }
                    textattr:=15;
                    clrscr;
                    dir('*.*');
                    gotoxy(1,24);
                    write('Enter filename to VIEW: ');
                    readln(filen);
                    if ((filen<>'') and okname(filen) and exist(filen)) then
                      view(filen);
                    printScreen;
                    redoall;
                    msg:='';
                  end;
              17: begin       { Alt - W }
                    textattr:=15;
                    clrscr;
                    dir('*.msg');
                    gotoxy(1,25);
                    write('Directory of menufile');
                    gotoxy(1,24);
                    write('Enter Menufile name: ');
                    readln(filen);
                    msg:='';
                    if ((filen<>'') and okname(filen) and exist(filen)) then
                    begin
                      dirmsg(filen);
                    end
                    else
                      msg:='Aborted';
                    printScreen;
                    redoall;
                  end;
              45: begin       { Alt - X }
                    if(not saved)then
                    begin
                      textattr:=15;
                      gotoxy(1,24);
                      clreol;
                      gotoxy(1,25);
                      clreol;
                      textattr:=red;
                      hilite('Picture not saved! Are you ^S^U^R^E you want to exit? ');
                      if (yn)then
                        done:=true;
                    end
                    else
                      done:=true;
                    redoall;
                  end;
              21: begin       { Alt - Y }
                    for c1:=y to 23 do
                      for c2:=1 to 80 do
                         begin
                           if(c1=23)then
                           begin
                             Screen[c2,c1]:=' ';
                             colors[c2,c1]:=curcolor;
                           end
                           else
                           begin
                             Screen[c2,c1]:=Screen[c2,c1+1];
                             colors[c2,c1]:=colors[c2,c1+1];
                           end;
                         end;
                    printScreen;
                    msg:='Line deleted';
                    saved:=false;
                  end;
              44: begin       { Alt - Z }
                    if(not saved)then
                    begin
                      textattr:=15;
                      gotoxy(1,24);
                      clreol;
                      gotoxy(1,25);
                      clreol;
                      textattr:=cyan;
                      write('Current picture not saved! Continue? ');
                      if(yn)then
                        ok:=true
                      else
                        ok:=false;
                    end
                    else
                      ok:=true;
                    if(ok)then
                    begin
                      textattr:=15;
                      clrscr;
                      dir('*.msg');
                      gotoxy(1,24);
                      write('Enter Menufile name: ');
                      readln(filen);
                      if ((filen<>'') and okname(filen) and exist(filen)) then
                      begin
                        gotoxy(1,24);
                        clreol;
                        write('Enter number of menu: ');
                        readln(s);
                        val(s,menunum,code);
                        if(code=0)then
                        begin
                          initScreen;
                          loadmsg(filen,menunum,ok);
                          if(ok)then
                          begin
                            filename:='MENU'+s+'.ANS';
                            msg:='Loaded '+filename+' OK.';
                          end
                          else
                          begin
                            msg:='Couldn''t load #'+s+' from menu file!';
                          end;
                          saved:=true;
                        end
                        else
                          msg:='Invalid number: '+s;
                      end
                      else
                      begin
                        msg:='Bad filename';
                      end;
                      printScreen;
                    end;
                    redoall;
                  end;
              82: begin       { Ins }
                    if(insert)then
                      insert:=false
                    else
                      insert:=true;
                    insmode;
                  end;
              83: begin       { Del }
                    for c1:=x to 79 do
                    begin
                      if (c1=79)then
                      begin
                        Screen[c1,y]:=' ';
                        colors[c1,y]:=curcolor;
                      end
                      else
                      begin
                        Screen[c1,y]:=Screen[c1+1,y];
                        colors[c1,y]:=colors[c1+1,y];
                      end;
                    end;
                    putline(y);
                    saved:=false;
                  end;
              72: begin                 {Up}
                    msg:='';
                    if(y>1)then
                      y:=y-1;
                  end;
              80: begin                 {Down}
                    msg:='';
                    if(y<23)then
                      y:=y+1;
                  end;
              75: begin                 {Left}
                    msg:='';
                    if(x>1)then
                      x:=x-1;
                  end;
              77: begin                 {Right}
                    msg:='';
                    if(x<79)then
                      x:=x+1;
                  end;
              71: begin                 {Home}
                    msg:='';
                    x:=1;
                  end;
              79: begin                 {End}
                    msg:='';
                    x:=79;
                  end;
              73: begin                 {PgUp}
                    msg:='';
                    y:=1;
                  end;
              81: begin                 {PgDn}
                    msg:='';
                    y:=23;
                  end;
              119: begin                {C-Home}
                     msg:='';
                     x:=1;
                     y:=1;
                   end;
              117: begin                {C-End}
                     msg:='';
                     x:=1;
                     y:=23;
                   end;
              132: begin                {C-PgUp}
                     msg:='';
                     x:=79;
                     y:=1;
                   end;
              118: begin                {C-PgDn}
                     msg:='';
                     x:=79;
                     y:=23;
                   end;
              115: begin                {C-Left}
                     if(curcolor=0)then
                       curcolor:=9
                     else
                       dec(curcolor);
                     newcolor;
                   end;
              116: begin                {C-Right}
                     if(curcolor=9)then
                       curcolor:=0
                     else
                       inc(curcolor);
                     newcolor;
                   end;
              else badkey;
            end;

          end;
      ' '..'˛': begin  {Character}
                  if(insert=false)then
                  begin
                    Screen[x,y]:=c;
                    colors[x,y]:=curcolor;
                    if(color)then
                      textattr:=colorset[colors[x,y]]
                    else
                      textattr:=monoset[colors[x,y]];
                    write(Screen[x,y]);
                  end
                  else
                  begin
                    for c1:=78 downto x do
                    begin
                      Screen[c1+1,y]:=Screen[c1,y];
                      colors[c1+1,y]:=colors[c1,y];
                    end;
                    Screen[x,y]:=c;
                    colors[x,y]:=curcolor;
                    putline(y);
                  end;
                  if(x<79)then inc(x);
                  saved:=false;
                  msg:='';
                end;
      #8: begin        {Backspace}
            if (x>1)then
            begin
              saved:=false;
              x:=x-1;
              for c1:=x to 79 do
              begin
                if (c1=79)then
                begin
                  Screen[c1,y]:=' ';
                  colors[c1,y]:=curcolor;
                end
                else
                begin
                  Screen[c1,y]:=Screen[c1+1,y];
                  colors[c1,y]:=colors[c1+1,y];
                end;
              end;
              putline(y);
            end;
            msg:=''
          end;
      #13: begin       {Enter}
             msg:='';
             if(y<23)then
             begin
               if(insert)then
               begin
                 curcbak:=curcolor;
                 curcolor:=0;
                 insertline(y+1);
                 for c1:=x to 79 do
                 begin
                   screen[c1-x+1,y+1]:=screen[c1,y];
                   colors[c1-x+1,y+1]:=colors[c1,y];
                   screen[c1,y]:=' ';
                   colors[c1,y]:=0;
                 end;
                 printscreen;
                 curcolor:=curcbak;
                 saved:=false;
               end;
               inc(y);
             end;
             x:=1;
           end;
      else badkey;
    end;
  until done;
  if(defaults.sfx)then
    fseffect(random(5))
  else
  begin
    textattr:=15;
    clrscr;
  end;
end.
