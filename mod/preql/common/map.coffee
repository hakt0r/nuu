$public class URMap
  x: 0
  y: 0
  scale: 8
  height: null
  mountain: []

  constructor: (@w,@h,@seed=32) ->
    # load Map from cache
    if (m = localStorage.getItem("urtc.map."+@seed))
      console.log 'cached'
      @height = new Int16Array str2ab m
    else # Generate Map
      Math.seedrandom(@seed)
      @height = new Int16Array @w*@h+@w+1
      for x in [0..@w-1]
       for y in [0..@h-1]
          @height[x+y*@w] = h = Math.round( (
              Math.floor(55.0 + 50 * Math.sin(0.5 * x / 16.0)) +
              Math.floor(55.0 + 50 * Math.sin(0.5 * y / 8.0)) +
              Math.floor(55.0 + 50 * Math.sin(0.5 * (x + y) / 16.0)) +
              Math.floor(55.0 + 50 * Math.sin(0.5 * Math.sqrt(x*x + y*y) / 8.0))
            ) / 4)
      @peak(Math.floor(Math.random()*@w),Math.floor(Math.random()*@h),200) for i in [0..10]
      localStorage.setItem("urtc.map."+@seed,ab2str(@height.buffer))
    # Initial render()
    win.on 'resize', @render
    do animate = => do @render; requestAnimationFrame animate
    $('body').on 'mousemove', => @hud()
    @map on

  peak: (x,y,h) =>
    @mountain[i] = m = x : x, y : y, h : h = Math.floor(Math.random()*h)
    h = @height[idx = x+y*@w] += h
    stack = [[x+1,y+1,h],[x-1,y+1,h],[x+1,y-1,h],[x-1,y-1,h],[x,y+1,h],[x,y-1,h],[x+1,y],[x-1,y,h]]
    have = new Int16Array(@w*@h+@w+1)
    have[idx] = 1
    c = 0
    while stack.length > 0
      stack = Array.shuffle stack if c++ % 10 is 0
      [x,y,h] = stack.shift()
      if have[idx = x+y*@w] isnt 1
        lh = @height[idx]
        if h - lh > 10
          have[idx] = 1
          if lh < 55
            @height[idx] = h = lh && h - 1 - Math.floor(Math.random() * 2)
          else @height[idx] = h = lh && h - 1 - Math.floor(Math.random() * 8)
          for i in [[x-1,y+1,h],[x+1,y-1,h],[x,y+1,h],[x,y-1,h],[x+1,y,h],[x-1,y,h],[x+1,y+1,h],[x-1,y-1,h]]
            stack.push i if have[i[0]+i[1]*@w] isnt 1
    @peak(Math.floor(Math.random()*50),Math.floor(Math.random()*50),h-Math.floor(10+Math.random()*20)) if h - 55 > 100

  walkmap: ->
    grid = []
    for y in [0..@h-1]
      grid.push row = []
      for x in [0..@w-1]
        row[x] = @height[x+y*@w]
        # row[x] = if 49 < (h=@height[x+y*@w]) < 101 then 0 else h
    grid

  debug: => console.log @
