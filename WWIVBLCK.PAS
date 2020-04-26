procedure bread(var block:screentype; var bcolor:cmap; tx,ty,bx,by:byte);
var c1,c2:byte;
begin
  for c1:=tx to bx do
    for c2:=ty to by do
    begin
      block[c1,c2]:=screen[c1,c2];
      bcolor[c1,c2]:=colors[c1,c2];
    end;
end;

procedure blockop(var cancel:boolean);
var topx,topy,botx,boty:byte;
    block:Screentype;
    bcolor:cmap;
    ch:char;
    done:boolean;
    key:char;
    acolor:byte;
begin
  textattr:=15;
  gotoxy(1,25);
  clreol;
  gotoxy(1,24);
  clreol;
  write('                  Press space to mark top left corner');
  getcpos(cancel,1,1);
  if (not cancel)then
  begin
    topx:=x;
    topy:=y;
    gotoxy(1,24);
    write('                  Press space to mark bottom right corner');
    cancel:=false;
    done:=false;
    repeat
      textattr:=15;
      gotoxy(1,25);
      write('(',x:2,',',y:2,')');
      revline(y,topx,x);
      revcol(x,topy,y);
      gotoxy(x,y);
      botcycle;
      ch:=readkey;
      if (ch=#0)then
      begin
        ch:=readkey;
        case ord(ch) of
          72: if(y>topy)then         {Up}
              begin
                y:=y-1;
                putline(y+1);
              end;
          80: if(y<23)then           {Down}
              begin
                y:=y+1;
                revline(y-1,topx,x);
              end;
          75: if(x>topx)then         {Left}
              begin
                x:=x-1;
                putcol(x+1);
              end;
          77: if(x<79)then           {Right}
              begin
                x:=x+1;
                revcol(x-1,topy,y);
              end;
          71: begin                  {Home}
                for c1:=x downto topx do
                  putcol(c1);
                x:=topx;
              end;
          79: begin                  {End}
                x:=79;
                for c1:=topx to x do
                  revcol(c1,topy,y);
              end;
          73: begin                  {PgUp}
                for c1:=y downto topy do
                  putline(c1);
                y:=topy;
              end;
          81: begin                  {PgDn}
                y:=23;
                for c1:=topy to y do
                  revline(c1,topx,x);
              end;
          119: begin                 {C-Home}
                 for c1:=x downto topx do
                   putcol(c1);
                 x:=topx;
                 for c1:=y downto topy do
                   putline(c1);
                 y:=topy;
               end;
          117: begin                 {C-End}
                 y:=23;
                 for c1:=topy to y do
                   revline(c1,topx,x);
                 for c1:=x downto topx do
                   putcol(c1);
                 x:=topx;
               end;
          132: begin                 {C-PgUp}
                 for c1:=y downto topy do
                   putline(c1);
                 y:=topy;
                 x:=79;
                 for c1:=topx to x do
                   revcol(c1,topy,y);
               end;
          118: begin                 {C-PgDn}
                 y:=23;
                 for c1:=topy to y do
                   revline(c1,topx,x);
                 x:=79;
                 for c1:=topx to x do
                   revcol(c1,topy,y);
               end;
          else badkey;
        end;
      end
      else
      begin
        case ch of
          ' ': begin
                 botx:=x;
                 boty:=y;
                 done:=true;
               end;
          #27: cancel:=true;
          else badkey;
        end;
      end;
    until ((cancel) or (done));
    if(not cancel)then
    begin
      textattr:=15;
      gotoxy(1,25);
      clreol;
      gotoxy(1,24);
      clreol;
      hilite('Block ^Delete/^Copy/^Move/^Fill: ');
      ch:=upcase(readkey);
      case ch of
        'D': begin
               for c1:=topy to boty do
                 for c2:=topx to botx do
                 begin
                   Screen[c2,c1]:=' ';
                   colors[c2,c1]:=curcolor;
                 end;
             end;
        'C': begin
               done:=false;
               cancel:=false;
               x:=topx;
               y:=topy;
               gotoxy(1,24);
               textattr:=15;
               clreol;
               bread(block,bcolor,topx,topy,botx,boty);
               write('                  Copy.. Move to position and press ENTER (ESC to cancel)');
               repeat
                 gotoxy(1,25);
                 textattr:=15;
                 clreol;
                 write('(',x:2,',',y:2,')');
                 gotoxy(x,y);
                 botcycle;
                 ch:=readkey;
                 if(ch=#0)then
                 begin
                   ch:=readkey;
                   case ord(ch) of
                     72: if(y>1)then
                         begin
                           putline(y+(boty-topy));
                           y:=y-1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     80: if(y<(23-(boty-topy)))then
                         begin
                           putline(y);
                           y:=y+1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     75: if(x>1)then
                         begin
                           putcol(x+(botx-topx));
                           x:=x-1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     77: if(x<(79-(botx-topx)))then
                         begin
                           putcol(x);
                           x:=x+1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     else badkey;
                   end;
                 end
                 else if(ch=#27)then cancel:=true
                 else if(ch=#13)then done:=true;
               until ((cancel) or (done));
               if(done)then
               begin
                 for c2:=topy to boty do
                 begin
                   for c1:=topx to botx do
                   begin
                     colors[x+(c1-topx),y+(c2-topy)]:=bcolor[c1,c2];
                     Screen[x+(c1-topx),y+(c2-topy)]:=block[c1,c2];
                   end;
                 end;
               end;
             end;
        'M': begin
               done:=false;
               cancel:=false;
               x:=topx;
               y:=topy;
               gotoxy(1,24);
               textattr:=15;
               clreol;
               bread(block,bcolor,topx,topy,botx,boty);
               write('                  Move.. Move to new position and press ENTER (ESC to cancel)');
               repeat
                 gotoxy(1,25);
                 textattr:=15;
                 clreol;
                 write('(',x:2,',',y:2,')');
                 gotoxy(x,y);
                 botcycle;
                 ch:=readkey;
                 if(ch=#0)then
                 begin
                   ch:=readkey;
                   case ord(ch) of
                     72: if(y>1)then
                         begin
                           putline(y+(boty-topy));
                           y:=y-1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     80: if(y<(23-(boty-topy)))then
                         begin
                           putline(y);
                           y:=y+1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     75: if(x>1)then
                         begin
                           putcol(x+(botx-topx));
                           x:=x-1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                     77: if(x<(79-(botx-topx)))then
                         begin
                           putcol(x);
                           x:=x+1;
                           putblock(block,bcolor,x,y,topx,topy,botx,boty);
                         end;
                   end;
                 end
                 else if(ch=#27)then cancel:=true
                 else if(ch=#13)then done:=true;
               until ((cancel) or (done));
               if(done)then
               begin
                 for c1:=topx to botx do
                   for c2:=topy to boty do
                   begin
                     screen[c1,c2]:=' ';
                     colors[c1,c2]:=curcolor;
                   end;
                 for c2:=topy to boty do
                   for c1:=topx to botx do
                   begin
                     colors[x+(c1-topx),y+(c2-topy)]:=bcolor[c1,c2];
                     Screen[x+(c1-topx),y+(c2-topy)]:=block[c1,c2];
                   end;
               end;
             end;
        'F': begin
               textattr:=1;
               gotoxy(1,25);
               clreol;
               gotoxy(1,24);
               clreol;
               hilite('Fill with ^Character or ^Attribute? ');
               ch:=upcase(readkey);
               if(ch='C')then
               begin
                 textattr:=15;
                 gotoxy(1,24);
                 clreol;
                 write('                  Press letter or fkey to fill block with (ESC to cancel)');
                 cancel:=false;
                 done:=false;
                 repeat
                   gotoxy(1,25);
                   write('Current set',curset:2,':');
                   textcolor(white);
                   textbackground(blue);
                   for c1:=1 to 10 do
                     write(' F',c1,'=',fsets[curset,c1]);
                   textattr:=15;
                   botcycle;
                   ch:=readkey;
                   case ch of
                     #0: begin
                           ch:=readkey;
                           case ord(ch) of
                             59..68: begin
                                       key:=fsets[curset][ord(ch)-58];
                                       done:=true;
                                     end;
                             104..113: begin
                                         curset:=ord(ch)-103;
                                       end;
                           end;
                         end;
                    ' '..'þ': begin
                                key:=ch;
                                done:=true;
                               end;
                     #27: cancel:=true;
                     else badkey;
                   end;
                 until((cancel) or (done));
                 if (not cancel)then
                 begin
                   for c1:=topx to botx do
                     for c2:=topy to boty do
                     begin
                       screen[c1,c2]:=key;
                     end;
                 end;
               end
               else if(ch='A')then
               begin
                 cancel:=false;
                 done:=false;
                 gotoxy(1,24);
                 clreol;
                 writeln('                  Attribute fill');
                 write('Color to fill area with (0-9, Q=Quit)? ');
                 repeat
                   botcycle;
                   ch:=upcase(readkey);
                   case ch of
                     #0: begin
                           ch:=readkey;
                           badkey;
                         end;
                     '0'..'9': begin
                                 acolor:=ord(ch)-ord('0');
                                 done:=true;
                               end;
                     'Q': cancel:=true;
                   end;
                 until ((cancel) or (done));
                 if(not cancel)then
                 begin
                   for c1:=topx to botx do
                     for c2:=topy to boty do
                       colors[c1,c2]:=acolor;
                 end;
               end;
             end;
        else begin
               badkey;
               cancel:=true;
             end;
      end;
    end;
  end;
end;

