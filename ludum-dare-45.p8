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
            body=new_body(128, 128, 8, 8)
        }
	end

    function update_player()
		move_player()
	end

    function move_player()
        dx=(btn(0) and-1 or 0)+(btn(1) and 1 or 0)
		dy=(btn(2) and-1 or 0)+(btn(3) and 1 or 0)
        player.body.speed.x += dx
        player.body.speed.y += dy*2
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
		if fm.x then newb.l+=dx newb.r+=dx end
		if fm.y then newb.t+=dy newb.b+=dy end
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
		fm={x=true,y=true}
		if dx !=0 then
			if(dx>0) x=b.r+1
			if(dx<0) x=b.l-1
			for y=b.t,b.b,1 do
				fm.x=(col_get_point(x,y,0)==nil)
				if(not fm.x) break
			end
		end
		if dy !=0 then
			if(dy>0) y=b.b+1
			if(dy<0) y=b.t-1
			for x=b.l,b.r,1 do
				fm.y=(col_get_point(x,y,0)==nil)
				if(not fm.y) break
			end
		end
		if(dx!=0 and dy!=0 and fm.x and fm.y)then
			if(dx>0)then x=b.r+1 else x=b.l-1 end
			if(dy>0)then y=b.b+1 else y=b.t-1 end
			if(col_get_point(x,y,0) !=nil) return {x=false,y=false}
		end
		return fm
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
        body.speed.x *= 0.8
    end

	function move_body(b)
		--if(not is_in_box(b.box.l,b.box.t,box(cam.x-8,cam.y-8,135,135))) return
		fm=col_free_move(b.box, b.speed.x*2, b.speed.y*2)
		fm.x=fm.x and not (b.box.l<0 and b.speed.x<0 or b.box.r>=1023 and b.speed.x>0)
		fm.y=fm.y and not (b.box.t<=0 and b.speed.y<0 or b.box.b>=255 and b.speed.y>0)
		if not fm.x then b.speed.x = 0 end
		if not fm.y then b.speed.y = 0 end
		b.box=col_move_box(b.box,b.speed.x*0.5,b.speed.y*0.5,fm)
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
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000766666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700765555670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000765005670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000765005670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700765555670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000766666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
00ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
