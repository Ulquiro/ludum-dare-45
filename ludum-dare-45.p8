pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-->8
--> MAIN
    function _init()
        init_player()
        init_camera()
    end

    function _update()
        update_player()
        update_bodies()
        update_camera()
    end

    function _draw()
        draw_camera()
        draw_map()
        draw_player()
		--print(str_num(player.body.speed.x).." "..str_num(player.body.speed.y), 0, 10, 7)
    end

-->8 PLAYER
    player={}
    startpos = {x=128,y=128}

    function init_player()
		player={
            body=new_body(128, 128, 7, 7),
			cols={b=false,l=false,r=false,t=false}
        }
	end

    function update_player()
		move_player()
		check_cols(player.body.box, player.cols)
	end

    function move_player()
        dx=(btn(0) and-1 or 0)+(btn(1) and 1 or 0)
        player.body.speed.x += dx*1.5
		if (btnp(2) and player.cols.b) then
        	player.body.speed.y += -10
		end
    end

    function draw_player()
        spr(0, player.body.box.l, player.body.box.t)
    end

-->8
-->8 CAMERA AND MAP
    cam={x=0,y=0}
	cam_bounds={}

    function init_camera()
		cam_bounds=abs_box(48,48,80,80)
	end

    function update_camera()
		cam_follow(player.body.box)
	end

	function draw_camera()
		cls()
	end

	function cam_move_to(x,y)
		cam.x=min(896,max(0,x))
		cam.y=min(128,max(0,y))
		camera(cam.x,cam.y)
	end

	function cam_focus(b)
		cam_move_to(b.l-64,b.t-64)
	end

	function cam_follow(b)
		dx=0
		dy=0

		c=box_s2w(cam_bounds)

		if(b.l<c.l) dx+=b.l-c.l
		if(b.r>c.r) dx+=b.r-c.r
		if(b.t<c.t) dy+=b.t-c.t
		if(b.b>c.b) dy+=b.b-c.b

		cam_move_to(cam.x+dx,cam.y+dy)
	end

--> MAP
    function draw_map()
		mx=flr(cam.x/8)
		my=flr(cam.y/8)
		map(mx,my,mx*8,my*8,17,17)
	end

-->8
--> COLLISIONS AND PHYSICS
--> COLLISIONS
	col_map={}

	function col_add_box(b)
		for x=b.l,b.r,1 do
			col_map[x.." "..b.t]=true
			col_map[x.." "..b.b]=true	
			if(x==b.l or x==b.r)then
				for y=b.t+1,b.b-1,1 do
					col_map[x.." "..y]=true
				end
			end
		end
	end

	function col_move_box(b,dx,dy,fm)
		if(dx==0 and dy==0) return b
		newb=cpy(b)
		if(fm==nil) fm=col_free_move(b,dx,dy)
		newb.l+=fm.x newb.r+=fm.x
		newb.t+=fm.y newb.b+=fm.y
		for x=b.l,b.r,1 do
			for y=b.t,b.b,1 do
				col_map[x.." "..y]=nil
			end
		end
		col_add_box(newb)
		return newb
	end

	function col_get_point(x,y,m)
		if((m==0) and band(0b1,fget(mget(flr(x/8),flr(y/8)))) !=0)then
			if(band(0b10,fget(mget(flr(x/8),flr(y/8))))!=0) return nil else return true
		end
		if((m==1) and band(0b1,fget(mget(flr(x/8),flr(y/8)))) !=0 or band(0b10,fget(mget(flr(x/8),flr(y/8))))!=0) return true
		if(col_map[x.." "..y] !=nil) return true
		return nil
	end

	function col_free_box(b,m)
		for x=b.l,b.r,1 do
			for y=b.t,b.b,1 do
				if(col_get_point(x,y,m)) return false
			end
		end
		return true
	end

	function col_free_move(b,dx,dy)
		fm={x=dx,y=dy}
		f={x=false,y=false}
		if(dx>0.1) x=b.r+dx
		if(dx<-0.1) x=b.l+dx
		while true do
			if abs(fm.x)<=0 then break end
			if f.x then break end
			for y=b.t,b.b,1 do
				f.x=(col_get_point(x,y,0)==nil)
				if not f.x then break end
			end
			if abs(fm.x)<=0 then break end
			if f.x then break end
			x-=sgn(dx)*0.1
			fm.x-=sgn(dx)*0.1
		end
		if(dy>0.1) y=b.b+dy
		if(dy<-0.1) y=b.t+dy
		while true do
			if abs(fm.y)<=0 then break end
			if f.y then break end
			for x=b.l,b.r,1 do
				f.y=(col_get_point(x,y,0)==nil)
				if not f.y then break end
			end
			if abs(fm.y)<=0 then break end
			if f.y then break end
			y-=sgn(dy)*0.1
			fm.y-=sgn(dy)*0.1
		end
		if abs(fm.x)>0 and abs(fm.y)>0 then
			if(fm.x>0)then x=b.r+fm.x else x=b.l+fm.x end
			if(fm.y>0)then y=b.b+fm.y else y=b.t+fm.y end
			while true do
				if(col_get_point(x,y,0)==nil) return fm
				if (sgn(dx)*fm.x<=0 or sgn(dy)*fm.y<=0) return {x=0,y=0}
				x-=sgn(dx)*dx*0.1
				y-=sgn(dy)*dy*0.1
				fm.x-=sgn(dx)*dx*0.1
				fm.y-=sgn(dy)*dy*0.1
			end
		end
		return fm
	end

	function new_check_cols()
		return {b=false, l=false, r=false, t=false}
	end

	function check_cols(b, c)
		y=b.t-1
		for x=b.l,b.r,1 do
			c.t=col_get_point(x,y,0)
			if(c.b) break
		end
		y=b.b+1
		for x=b.l,b.r,1 do
			c.b=col_get_point(x,y,0)
			if(c.b) break
		end
		x=b.l-1
		for y=b.t,b.b,1 do
			c.l=col_get_point(x,y,0)
			if(c.l) break
		end
		x=b.r+1
		for y=b.t,b.b,1 do
			c.r=col_get_point(x,y,0)
			if(c.r) break
		end
	end

--> PHYSICS
    bodies={}
    gravity={x=0,y=1}

	function update_bodies()
		for i=1,#bodies,1 do
            bodies[i].speed.x+=gravity.x
            bodies[i].speed.y+=gravity.y
            friction(bodies[i])
            move_body(bodies[i])
		end
	end

	function new_body(x,y,sx, sy)
		body={
			box=box(x,y,sx,sy),
			speed={x=0,y=0}
		}
		col_add_box(body.box)
        add(bodies, body)
		return body
	end

    function friction(body)
        if (abs(body.speed.x)>0) body.speed.x *= 0.8
        if (abs(body.speed.x)>7) body.speed.x = sgn(body.speed.x)*7
        if (abs(body.speed.y)>7) body.speed.y = sgn(body.speed.y)*7
    end

	function move_body(b)
		fm=col_free_move(b.box, b.speed.x, b.speed.y)
		b.speed.x = fm.x
		b.speed.y = fm.y
		b.box=col_move_box(b.box,fm.x,fm.y, fm)
	end

-->8
--> BOX AND UTILS
--> BOX

	function box(x,y,w,h)
		return {l=x,t=y,r=x+w,b=y+h}
	end

	function abs_box(l,t,r,b)
		return {l=l,t=t,r=r,b=b}
	end
	
	function spr_box(x,y)
		return box(x,y,8,8)
	end
	
	function txt_box(str,x,y)
		return box(x,y,4 * #str,5)
	end
	
	function is_in_box(x,y,b)
		return x>=b.l and x<=b.r and y>=b.t and y<=b.b
	end

	function clear_box(b)
		rectfill(b.l,b.t,b.r,b.b,0)
	end

	function draw_box(b,c)
		c=c or 7
		line(b.l+1,b.t,b.r-1,b.t,c)
		line(b.l,b.t+1,b.l,b.b-1,c)
		line(b.r,b.t+1,b.r,b.b-1,c)
		line(b.l+1,b.b,b.r-1,b.b,c)
	end

	function draw_clear_box(b)
		clear_box(box_s2w(add_box(abs_box(1,1,-1,-1),b)))
		draw_box(box_s2w(b))
	end

	function box_w2s(b)
		return abs_box(b.l-cam.x,b.t-cam.y,b.r-cam.x,b.b-cam.y)
	end

	function box_s2w(b)
		return abs_box(b.l+cam.x,b.t+cam.y,b.r+cam.x,b.b+cam.y)
	end

	function add_box(b1,b2)
		return abs_box(b1.l+b2.l,b1.t+b2.t,b1.r+b2.r,b1.b+b2.b)
	end

--> UTILS
	function str_num(n,d)
		str=''..n
		for i=0,d-#str-1,1 do str='0'..str end
		return n<1 and sub(str,2) or str
	end

	function printui(t,x,y,c)
		print(t,x+cam.x,y+cam.y,c)
	end

	function sprui(s,x,y)
		spr(s,x+cam.x,y+cam.y)
	end

    function cpy(orig)
		new={}
		for k,v in pairs(orig) do
			new[k]=v
		end
		return new
	end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000006660000006600000666000000660000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000
006e6000006e6600006e6000006e6600006e6000006e660000000000000000000000000000000000000000000000000000000000000000000000000000000000
066e6066606ee600066e6066606ee600066e6066606ee60000dd00000000000000dd00000000000000dd00d00000000000000000000000000000000000000000
06ee6666666ee60006ee6666666ee60006ee6666666ee6000d00d0000000000000d0d000000000000d00dd000000000000000000000000000000000000000000
066666c6c6666600066666c6c6666600066666c6c66666000d00d000000000000d000d00000000000d0000000000000000000000000000000000000000000000
0000666666600000000066666660000000006666666000000d000000060000000d000000000000000d0000000600000000000000000000000000000000000000
0000666e666000000000666e666000000000666e6660000000dd00006e60000000d000000600000000d000006e60000000000000000000000000000000000000
00000566650000d00000056665000d00000005666500d000000d00006e600000000d00006e600000000d00006e60000000000000000000000000000000000000
0000555155500d0000005551555000d0000055515550d0000055555566660000005555556e660000005555556666000000000000000000000000000000000000
0000555d55500d000000555d555000d00000555d5550d00005555555556c600005555555556c600005555555556c600000000000000000000000000000000000
0000555d55500d000000555d555000d00000555d55500d000555555555666e000555555555666e000555555555666e0000000000000000000000000000000000
0000555d5550d0000000555d5550dd000000555d55500d0005555555556660000555555555666000055555555566600000000000000000000000000000000000
00005555555d000000005555555d000000005555555dd00005f5555f5566000005f5555f5566000005f5555f5566000000000000000000000000000000000000
00000555550000000000055555000000000005555500000000f0000f0000000000f0000f0000000000f0000f0000000000000000000000000000000000000000
000ffff5ffff0000000ffff5ffff0000000ffff5ffff000000ff000ff0000000000f000f0000000000f00000f000000000000000000000000000000000000000
00066000006660006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006e6000006e60006ee6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06ee6000006ee6006e66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666066606666006666c60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000666c6c6660000066666e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006666666000000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00666e66600f000555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00056665000fd0f555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f50555155505f0df555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0555555d5555550df555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055555d5555000d055555500d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000555d55500dd005555550d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005555555dd00005555500d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000055555000000f555d00d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ffff5ffff0000f5500dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000100010001000100010000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000001010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
