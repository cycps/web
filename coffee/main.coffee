root = exports ? this

getParameterByName = (name) =>
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
    results = regex.exec(location.search)
    decodeURIComponent(results[1].replace(/\+/g, " "))

initViz = () =>
  g.ve = new VisualEnvironment(document.getElementById("surface"))
  g.ve.ebox = new StaticElementBox(g.ve, 120, g.ve.height/2 - 65)
  mh = g.ve.height - 140
  g.ve.mbox = new ModelBox(g.ve, mh, (g.ve.height - 140)/2 - mh/2.0 - 60)
  g.ve.surface = new Surface(g.ve)
  g.ve.datgui = null
  g.ve.render(g.ve)

dsg = ""

#Entry point
root.go = ->
  ($.get "/gatekeeper/thisUser", (data) =>
    g.user = data
    console.log("the user is " + g.user)
    g.xp = getParameterByName("xp")
    dsg = g.xp
    console.log("the xp is " + g.xp)
    initViz()
    #loadXP()
    g.ve.addie.load()
    true
  ).fail () ->
    console.log("fail to get current user, going back to login screen")
    window.location.href = location.origin
    true

#Global event handlers
root.vz_mousedown = (event) ->
  g.ve.mouseh.ondown(event)

root.swapcontrol = (event) =>
  g.ve.xpcontrol.swapIn()

root.newModel = (event) ->
  g.ve.mbox.newModel()

root.save = () =>
  g.ve.xpcontrol.save()

root.analyze = () =>
  g.ve.addie.analyze()

#Global state holder
g = {}

#Shapes contains a collection of classes that comprise the basic shapes used to
#represent Cypress CPS elements
Shapes = {

  Rectangle : class Rectangle
    constructor: (color, x, y, z, width, height) ->
      @geom = new THREE.PlaneBufferGeometry(width, height)
      @material = new THREE.MeshBasicMaterial({color: color})
      @obj3d = new THREE.Mesh(@geom, @material)
      @obj3d.position.x = x
      @obj3d.position.y = y
      @obj3d.position.z = z
      @obj3d.linep = new THREE.Vector3(x, y, 5)
      @obj3d.lines = []

    select: ->

  Circle : class Circle
    constructor: (color, x, y, z, radius) ->
      @geom = new THREE.CircleGeometry(radius, 64)
      @material = new THREE.MeshBasicMaterial({color: color})
      @obj3d = new THREE.Mesh(@geom, @material)
      @obj3d.position.x = x
      @obj3d.position.y = y
      @obj3d.position.z = z
      @obj3d.linep = new THREE.Vector3(x, y, 5)
      @obj3d.lines = []

    select: ->

  Diamond: class Diamond
    constructor: (color, x, y, z, l) ->
      @shape = new THREE.Shape()
      @shape.moveTo(0,l)
      @shape.lineTo(l,0)
      @shape.lineTo(0,-l)
      @shape.lineTo(-l,0)
      @shape.lineTo(0,l)

      @material = new THREE.MeshBasicMaterial({color: color})
      @geom = new THREE.ShapeGeometry(@shape)
      @obj3d = new THREE.Mesh(@geom, @material)
      @obj3d.position.x = x
      @obj3d.position.y = y
      @obj3d.position.z = z
      @obj3d.linep = new THREE.Vector3(x, y, 5)
      @obj3d.lines = []
    
    select: ->

  Line: class Line
    constructor: (color, from, to, z) ->
      @material = new THREE.LineBasicMaterial({color: color, linewidth: 3})
      @geom = new THREE.Geometry()
      @geom.dynamic = true
      @geom.vertices.push(from, to)
      @obj3d = new THREE.Line(@geom, @material)
      @obj3d.position.x = 0
      @obj3d.position.y = 0
      @obj3d.position.z = z
      @obj3d.lines = []
    
    select: ->

  SelectionCube: class SelectionCube
    constructor: () ->
      @geom = new THREE.Geometry()
      @geom.dynamic = true

      @aa = new THREE.Vector3(0, 0, 75)
      @ab = new THREE.Vector3(0, 0, 75)
      @ba = new THREE.Vector3(0, 0, 75)
      @bb = new THREE.Vector3(0, 0, 75)

      @geom.vertices.push(
        @aa, @ab, @ba,
        @bb, @ba, @ab
      )

      @geom.faces.push(
        new THREE.Face3(0, 1, 2),
        new THREE.Face3(2, 1, 0),
        new THREE.Face3(3, 4, 5),
        new THREE.Face3(5, 4, 3)
      )

      @geom.computeBoundingSphere()
      @material = new THREE.MeshBasicMaterial(
        {
          color: 0x7800ff,
          opacity: 0.2,
          transparent: true
        }
      )
      @obj3d = new THREE.Mesh(@geom, @material)

    updateGFX: () ->
      @geom.verticesNeedUpdate = true
      @geom.lineDistancesNeedUpdate = true
      @geom.elementsNeedUpdate = true
      @geom.normalsNeedUpdate = true
      @geom.computeFaceNormals()
      @geom.computeVertexNormals()
      @geom.computeBoundingSphere()
      @geom.computeBoundingBox()

    init: (p) ->
      @aa.x = @ab.x = @ba.x = p.x
      @aa.y = @ba.y = @ab.y = p.y
      @bb.x = @aa.x
      @bb.y = @aa.y
      @updateGFX()


    update: (p) ->
      @bb.x = @ba.x = p.x
      @bb.y = @ab.y = p.y
      @updateGFX()

    reset: () ->
      @aa.x = @bb.x = @ba.x = @ab.x = 0
      @aa.y = @bb.y = @ba.y = @ab.y = 0
      @updateGFX()

}

#The BaseElements object holds classes which are Visual representations of the
#objects that comprise a Cypress networked CPS system
BaseElements = {

  updateId: (e) ->
    e.onIdUpdate() if e.onIdUpdate?
    e.id.name = e.props.name
    if e.id.sys?
      e.id.sys = e.props.sys

  currentId: (d) ->
    {name: d.props.name, sys: d.props.sys, design: dsg }
 
  #The Computer class is a representation of a computer
  Computer: class Computer
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Diamond(0x2390ff, x, y, z, 15)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "computer0",
        sys: "root",
        os: "Ubuntu1504-54-STD",
        start_script: "",
        interfaces: {}
      }
      @id = {
        name: "computer0"
        sys: "root"
        design: dsg
      }
      @links = []

    showProps: (f) ->
      c = f.add(@props, 'name')
      c = f.add(@props, 'sys')
      c = f.add(@props, 'start_script')
      c = f.add(@props, 'os')



    #cyjs generates the json for this object
    cyjs: ->

  #The Model class is a represenation of a mathematical model of a physical object
  Model: class Model
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Rectangle(0x239f5a, x, y, z, 25, 25)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "model0",
        params: "",
        equations: ""
      }
      @id = {
        name: "model0"
      }
      @instances = []

    instantiate: (parent, x, y, z) ->
      obj = new Phyo(parent, x, y, z)
      obj.props.model = @props.name
      obj


    #cyjs generates the json for this object
    cyjs: ->
  
  Phyo: class Phyo
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Rectangle(0x239f5a, x, y, z, 25, 25)
      @shp.obj3d.userData = this
      @model = null
      if @parent?
        @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "model0",
        sys: "root",
        model: ""
        args: "",
      }
      @id = {
        name: "model0",
        sys: "root",
        design: dsg
      }
      @links = []
      @args = []

    addArgs: () ->
      _args = @model.props.params
        .replace(" ", "")
        .split(",")
        .map((x) -> x.replace(" ", ""))
        .filter((x) -> x.length != 0)

      for p in _args
        if !@props[p]?
          @props[p] = ""

      for p in @args
        if p not in _args
          delete @props[p]

      @args = _args
      true

    loadArgValues: () ->
      _args = @props.args
        .split(",")
        .filter((x) -> x.length != 0)
        .map((x) -> x.split("=").filter((y) -> y.length != 0))

      for x in _args
        @props[x[0]] = x[1]
        @args.push(x[0])

    sync: ->
      if @model?
        @props.model = @model.props.name
        @addArgs()
        @props.args = ""
        for p in @args
          @props.args += (p+"="+@props[p]+",")

    onIdUpdate: ->
      for x in @links
        if @id.name != @props.name
          x.props[@props.name] = x.props[@id.name]
          delete(x.props[@id.name])


    #cyjs generates the json for this object
    cyjs: ->

  #The Sax class is a representation of a sensing and acutation unit
  Sax: class Sax
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Circle(0x239f9c, x, y, z, 7)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "sax0",
        sys: "root",
        design: dsg,
        sense: "",
        actuate: ""
        interfaces: {}
      }
      @id = {
        name: "sax0",
        sys: "root",
        design: dsg
      }
      @links = []
    
    #cyjs generates the json for this object
    cyjs: ->


  #Router is a visual representation of an IP-network router 
  Router: class Router
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Circle(0x23549F, x, y, z, 15)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      #TODO you are here, all objects with changable props should have a props 
      #object
      @props = {
        name: "router0",
        sys: "root",
        capacity: 100,
        latency: 0,
        interfaces: {}
      }
      @id = {
        name: "router0"
        sys: "root"
        design: dsg
      }
      @links = []

    showProps: (f) ->
      f.add(@props, 'name')
      f.add(@props, 'sys')
      f.add(@props, 'capacity')
      f.add(@props, 'latency')
    
    
    #cyjs generates the json for this object
    cyjs: ->

  #Switch is a visual representation of an IP-network swtich
  Switch: class Switch
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Rectangle(0x23549F, x, y, z, 25, 25)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "switch0",
        sys: "root",
        capacity: 1000,
        latency: 0,
        interfaces: {}
      }
      @id = {
        name: "switch0"
        sys: "root"
        design: dsg
      }
      @links = []

    showProps: (f) ->
      f.add(@props, 'name')
      f.add(@props, 'sys')
      f.add(@props, 'capacity')
      f.add(@props, 'latency')
    
    
    #cyjs generates the json for this object
    cyjs: ->

  Link: class Link
    constructor: (@parent, from, to, x, y, z, isIcon = false) ->
      @endpoint = [null, null]
      @ep_ifx = ["",""]
      #TODO: s/ln/shp/g for consistency
      @ln = new Shapes.Line(0xababab, from, to, z)
      @ln.obj3d.userData = this
      @props = {
        name: "link0",
        sys: "root",
        design: dsg,
        capacity: 1000,
        latency: 0,
        endpoints: [
          {name: "link0", sys: "root", design: dsg, ifname: ""},
          {name: "link0", sys: "root", design: dsg, ifname: ""}
        ]
      }
      @id = {
        name: "link0"
        sys: "root"
        design: dsg
      }

      #TODO if ln itself is clicked on this messes up selection logic 
      if isIcon
        @shp = new Shapes.Rectangle(@parent.material.color, x, y, z, 25, 25)
        @shp.obj3d.userData = this
        @shp.obj3d.add(@ln.obj3d)
        @parent.obj3d.add(@shp.obj3d)
      else
        @parent.obj3d.add(@ln.obj3d)

    isInternet: ->
      @endpoint[0] instanceof Router and @endpoint[1] instanceof Router

    isPhysical: ->
      @endpoint[0] instanceof Phyo and @endpoint[1] instanceof Phyo or
      @endpoint[0] instanceof Phyo and @endpoint[1] instanceof Sax or
      @endpoint[1] instanceof Phyo and @endpoint[0] instanceof Sax

    isIfxPhysical: (i) ->
      @endpoint[i] instanceof Phyo
      #@endpoint[i] instanceof Sax
    


    applyWanProps: ->
      @props.capacity = 100
      @props.latency = 7

    applyPhysicalProps: ->
      @props = {
        name: @props.name,
        sys: @props.sys,
        design: @props.design,
        endpoints: [
          {name: "link0", sys: "root", design: dsg},
          {name: "link0", sys: "root", design: dsg}
        ],
        bindings: ["",""]
      }
      @props[@endpoint[0].props.name] = "" if @endpoint[0] #instanceof Phyo
      @props[@endpoint[1].props.name] = "" if @endpoint[1] #instanceof Phyo

    setEndpointData: ->
      @props.endpoints[0].name = @endpoint[0].props.name
      @props.endpoints[0].sys = @endpoint[0].props.sys
      if !@isIfxPhysical(1) #yes, this is based on the other side of the connection
        @props.endpoints[0].ifname = @ep_ifx[0]
      if @isPhysical()
        @props.bindings[0] = @props[@endpoint[0].props.name]

      @props.endpoints[1].name = @endpoint[1].props.name
      @props.endpoints[1].sys = @endpoint[1].props.sys
      if !@isIfxPhysical(0)
        @props.endpoints[1].ifname = @ep_ifx[1]
      if @isPhysical()
        @props.bindings[1] = @props[@endpoint[1].props.name]

    unpackBindings: ->
          @props[@endpoint[0].props.name] = @props.bindings[0]
          @props[@endpoint[1].props.name] = @props.bindings[1]

    ifInternetToWanLink:  ->
      @applyWanProps() if @isInternet()

    ifPhysicalToPlink: ->
      @applyPhysicalProps() if @isPhysical()
    
    showProps: (f) ->
      f.add(@props, 'name')
      f.add(@props, 'sys')
      f.add(@props, 'capacity')
      if @isInternet()
        f.add(@props, 'latency')

    #cyjs generates the json for this object
    cyjs: ->

}

#The ElementBox holds Element classes which may be added to a system,
#aka the thing on the left side of the screen
class ElementBox
  #Constructs an ElementBox object given a @ve visual environment
  constructor: (@ve, @height, @y) ->
    #@height = @ve.height - 10
    @width = 75
    @x = -@ve.width/2  + @width / 2 + 5
    #@y =  0
    @z = 5
    @box = new Shapes.Rectangle(0x404040, @x, @y, @z, @width, @height)
    @box.obj3d.userData = this
    @ve.scene.add(@box.obj3d)
    @count = 0
    @addBaseElements()

  #addElement adds a visual element to the ElementBox given an element
  #contruction lambda ef : (box, x, y) -> Object3D
  addElement: (ef) ->
    row = Math.floor(@count / 2)
    col = @count % 2

    _x = if col == 0 then -18 else 18
    _y = (@height / 2 - 25) - row * 35
    e = ef(@box, _x, _y)
    @count++
    e

  #addBaseElements adds the common base elements to the ElementBox
  addBaseElements: ->

class StaticElementBox extends ElementBox
  addBaseElements: ->
    @addElement((box, x, y) -> new BaseElements.Computer(box, x, y, 5))
    @addElement((box, x, y) -> new BaseElements.Router(box, x, y, 5))
    @addElement((box, x, y) -> new BaseElements.Switch(box, x, y, 5))
    @addElement((box, x, y) ->
      new BaseElements.Link(box,
        new THREE.Vector3(-12.5, 12.5, 5), new THREE.Vector3(12.5, -12.5, 5),
        x, y, 5, true
      )
    )
    @addElement((box, x, y) -> new BaseElements.Sax(box, x, y, 5))


class ModelBox extends ElementBox
  newModel: ()->
    m = @addElement((box, x, y) -> new BaseElements.Model(box, x, y, 5))
    m.props.name = @ve.namemanager.getName("model")
    m.id.name = m.props.name
    @ve.render()
    @ve.addie.update([m])

  addBaseElements: ->
    #@addElement((box, x, y) -> new BaseElements.Model(box, x, y, 5))

#The Surface holds visual representations of Systems and Elements
#aka the majority of the screen
class Surface
  #Constructs a Surface object given a @ve visual environment
  constructor: (@ve) ->
    @height = @ve.height
    @width = @ve.width
    @baseRect = new Shapes.Rectangle(0x262626, 0, 0, 0, @width, @height)
    @baseRect.obj3d.userData = this
    @ve.scene.add(@baseRect.obj3d)
    @selectGroup = new THREE.Group()
    @ve.scene.add(@selectGroup)
    @selectorGroup = new THREE.Group()
    @ve.scene.add(@selectorGroup)
    @elements = []

  addElement: (ef, x, y) ->
    e = new ef.constructor(@baseRect, x, y, 50)
    e.props.name = @ve.namemanager.getName(e.constructor.name.toLowerCase())
    e.id.name = e.props.name
    e.props.design = dsg
    @elements.push(e)
    @ve.render()
    e

  getElement: (name, sys) ->
    e = null
    for x in @elements
      if x.props.name == name  && x.props.sys == sys
        e = x
        break
    e


  addIfContains: (box, e, set) ->
    o3d = null
    if e.shp?
      o3d = e.shp.obj3d
    else if e.ln?
      o3d = e.ln.obj3d
    if o3d != null
      o3d.geometry.computeBoundingBox()
      bb = o3d.geometry.boundingBox
      bx = new THREE.Box2(
        o3d.localToWorld(bb.min),
        o3d.localToWorld(bb.max)
      )
      set.push(e) if box.containsBox(bx)

      #for some reason computing the bounding box kills selection
      o3d.geometry.boundingBox = null
    true

  toBox2: (box) ->
    new THREE.Box2(
      new THREE.Vector2(box.min.x, box.min.y),
      new THREE.Vector2(box.max.x, box.max.y)
    )

  getSelection: (box) ->
    xs = []
    box2 = @toBox2(box)
    @addIfContains(box2, x, xs) for x in @elements
    xs

  
  updateLink: (ln) ->
    ln.geom.verticesNeedUpdate = true
    ln.geom.lineDistancesNeedUpdate = true
    ln.geom.elementsNeedUpdate = true
    ln.geom.normalsNeedUpdate = true
    ln.geom.computeFaceNormals()
    ln.geom.computeVertexNormals()
    ln.geom.computeBoundingSphere()
    ln.geom.computeBoundingBox()

  moveObject: (o, p) ->
    o.position.x = p.x
    o.position.y = p.y
    o.linep.x = p.x
    o.linep.y = p.y

    if o.userData.glowBubble?
      o.userData.glowBubble.position.x = p.x
      o.userData.glowBubble.position.y = p.y

    @updateLink(ln) for ln in o.lines
    true

  moveSelection: -> #TODO
  
  glowMaterial: () ->
    cam = @.ve.camera
    new THREE.ShaderMaterial({
      uniforms: {
          "c": { type: "f", value: 1.0 },
          "p": { type: "f", value: 1.4 },
          glowColor: { type: "c", value: new THREE.Color(0x7800ff) },
          viewVector: { type: "v3", value: cam.position }
      },
      vertexShader: document.getElementById("vertexShader").textContent,
      fragmentShader: document.getElementById("fragmentShader").textContent,
      side: THREE.FrontSide,
      blending: THREE.AdditiveBlending,
      transparent: true
    })

  glowSphere: (radius, x, y, z) ->
    geom = new THREE.SphereGeometry(radius, 64, 64)
    mat = @glowMaterial()
    obj = new THREE.Mesh(geom, mat)
    obj.position.x = x
    obj.position.y = y
    obj.position.z = z
    obj

  glowCube: (width, height, depth, x, y, z) ->
    geom = new THREE.BoxGeometry(width, height, depth, 2, 2, 2)
    mat = @glowMaterial()
    obj = new THREE.Mesh(geom, mat)
    obj.position.x = x
    obj.position.y = y
    obj.position.z = z
    modifier = new THREE.SubdivisionModifier(2)
    modifier.modify(geom)
    obj

  glowDiamond: (w, h, d, x, y, z) ->
    obj = @glowCube(w, h, d, x, y, z)
    obj.rotateZ(Math.PI/4)
    obj

  clearPropsGUI: ->
    if @ve.datgui?
      @ve.datgui.destroy()
      @ve.datgui = null

  showPropsGUI: (s) ->
    @ve.datgui = new dat.GUI()

    addElem = (d, k, v) ->
      if !d[k]?
        d[k] = [v]
      else
        d[k].push(v)

    dict = new Array()
    addElem(dict, x.constructor.name, x) for x in s

    addGuiElems = (typ, xs) =>
      f = @ve.datgui.addFolder(typ)
      x.showProps(f) for x in xs
      f.open()

    addGuiElems(k, v) for k,v of dict

    $(@ve.datgui.domElement).focusout () =>
      @ve.addie.update([x]) for x in s

    true

  selectObj: (obj) ->

    if not obj.glowBubble?
      if obj.shp instanceof Shapes.Circle
        p = obj.shp.obj3d.position
        s = obj.shp.geom.boundingSphere.radius + 3
        gs = @glowSphere(s, p.x, p.y, p.z)
      else if obj.shp instanceof Shapes.Rectangle
        p = obj.shp.obj3d.position
        s = obj.shp.geom.boundingSphere.radius + 3
        l = s*1.5
        gs = @glowCube(l, l, l, p.x, p.y, p.z)
      else if obj.shp instanceof Shapes.Diamond
        p = obj.shp.obj3d.position
        s = obj.shp.geom.boundingSphere.radius + 3
        l = s*1.5
        gs = @glowDiamond(l, l, l, p.x, p.y, p.z)
      else if obj.ln instanceof Shapes.Line
        d = 10
        h = 10
        v0 = obj.ln.geom.vertices[0]
        v1 = obj.ln.geom.vertices[obj.ln.geom.vertices.length - 1]
        w = obj.ln.geom.boundingSphere.radius * 2
        x = (v0.x + v1.x) / 2
        y = (v0.y + v1.y) / 2
        z = 5
        gs = @glowCube(w, h, d, x, y, z)
        theta = Math.atan2(v0.y - v1.y, v0.x - v1.x)
        gs.rotateZ(theta)
      else
        console.log "unkown object to select"
        console.log obj

      gs.userData = obj
      obj.glowBubble = gs
      @selectGroup.add(gs)
      @ve.render()
    true

  clearSelection: ->
    delete gb.userData.glowBubble for gb in @selectGroup.children
    @selectGroup.children = []
    @clearPropsGUI()
    @ve.render()

  clearSelector: ->
    @selectorGroup.children = []
    @ve.render()

class NameManager
  constructor: () ->
    @names = new Array()

  getName: (s) ->
    if !@names[s]?
      @names[s] = 0
    else
      @names[s]++

    s + @names[s]

class ExperimentControl
  constructor: (@ve) ->
  
  expJson: ->
    console.log "Generating experiment json for " + @ve.surface.elements.length +
      " elements"

    data = {
      computers: [],
      routers: [],
      switches: [],
      lan_links: [],
      wan_links: []
    }

    linkAdd = (l) ->
      switch
        when l.isInternet() then data.wan_links.push(l.props)
        else data.lan_links.push(l.props)

    add = (e) ->
      switch
        when e instanceof BaseElements.Computer then data.computers.push(e.props)
        when e instanceof BaseElements.Router then data.routers.push(e.props)
        when e instanceof BaseElements.Switch then data.switches.push(e.props)
        when e instanceof BaseElements.Link then linkAdd(e)
        else console.log('unkown element -- ', e)

    add(e) for e in @ve.surface.elements

    console.log(data)
    console.log(JSON.stringify(data, null, 2))

    data

  save: ->
    console.log("saving experiment")

    console.log("to the bakery!")

    console.log("getting")
    $.get "addie/bakery", (data) =>
      console.log("bakery GET")
      console.log(data)
    
    console.log("posting")
    $.post "addie/bakery", (data) =>
      console.log("bakery POST")
      console.log(data)

  swapIn: ->
    @expJson()

  swapOut: ->

  update: ->


#VisualEnvironment holds the state associated with the Threejs objects used
#to render Surfaces and the ElementBox. This class also contains methods
#for controlling and interacting with this group of Threejs objects.
class VisualEnvironment

  #Constructs a visual environment for the given @container. @container must
  #be a reference to a <div> dom element. The Threejs canvas the visual 
  #environment renders onto will be appended as a child of the supplied 
  #container
  constructor: (@container) ->
    @scene = new THREE.Scene()
    @width = @container.offsetWidth
    @height = @container.offsetHeight
    @camera = new THREE.OrthographicCamera(
      @width / -2, @width / 2,
      @height / 2, @height / -2,
      1, 1000)
    @renderer = new THREE.WebGLRenderer({antialias: true, alpha: true})
    @renderer.setSize(@width, @height)
    @clear = 0x262626
    @alpha = 1
    @renderer.setClearColor(@clear, @alpha)
    @container.appendChild(@renderer.domElement)
    @camera.position.z = 200
    @mouseh = new MouseHandler(this)
    @raycaster = new THREE.Raycaster()
    @raycaster.linePrecision = 10
    @namemanager = new NameManager()
    @xpcontrol = new ExperimentControl(this)
    @addie = new Addie(this)
    @propsEditor = new PropsEditor(this)
    @equationEditor = new EquationEditor(this)

  render: ->
    @renderer.clear()
    @renderer.clearDepth()
    @renderer.render(@scene, @camera)

#This is the client side Addie, it talks to the Addie at cypress.deterlab.net
#to manage a design
class Addie
  constructor: (@ve) ->

  update: (xs) =>
    console.log("updating objects")
    console.log(xs)

    #build the update sets
    link_updates = {}
    node_updates = {}
    model_updates = {}

    for x in xs

      if x.links? #x is a node if it has links
        node_updates[JSON.stringify(x.id)] = x
        for l in x.links
          link_updates[JSON.stringify(l.id)] = l

      if x instanceof BaseElements.Link
        link_updates[JSON.stringify(x.id)] = x
        node_updates[JSON.stringify(x.endpoint[0].id)] = x.endpoint[0]
        node_updates[JSON.stringify(x.endpoint[1].id)] = x.endpoint[1]

      if x instanceof BaseElements.Model
        model_updates[x.id.name] = x
        for i in x.instances
          node_updates[JSON.stringify(i.id)] = i

      true

    #build the update messages
    model_msg = { Elements: [] }
    node_msg = { Elements: [] }
    link_msg = { Elements: [] }

    for _, m of model_updates
      model_msg.Elements.push(
        {
          OID: { name: m.id.name, sys: "", design: dsg },
          Type: "Model", Element: m.props
        }
      )
      true

    for _, n of node_updates
      node_msg.Elements.push(
        { OID: n.id, Type: n.constructor.name, Element: n.props }
      )
      true

    for _, l of link_updates
      type = "Link"
      type = "Plink" if l.isPhysical()
      link_msg.Elements.push(
        { OID: l.id, Type: type, Element: l.props }
      )
      true

    doLinkUpdate = () =>
      console.log("link update")
      console.log(link_msg)
        
      if link_msg.Elements.length > 0
        $.post "/addie/"+dsg+"/design/update", JSON.stringify(link_msg), (data) =>
          for _, l of link_updates
            BaseElements.updateId(l)

    doNodeUpdate = () =>
      console.log("node update")
      console.log(node_msg)

      if node_msg.Elements.length > 0
        $.post "/addie/"+dsg+"/design/update", JSON.stringify(node_msg), (data) =>
          for _, n of node_updates
            BaseElements.updateId(n)
          for _, l of link_updates
            l.setEndpointData()

          doLinkUpdate()

    doModelUpdate = () =>
      console.log("model update")
      console.log(model_msg)

      if model_msg.Elements.length > 0
        $.post "/addie/"+dsg+"/design/update", JSON.stringify(model_msg), (data) =>
          for _, m of model_updates
            BaseElements.updateId(m)
          for _, n of node_updates
            n.sync() if n.sync?

          doNodeUpdate()


    #do the updates since this is a linked structure we have to be a bit careful
    #about update ordering, here we do models, then nodes then links. This is
    #because some nodes reference models, and all links reference nodes. At
    #each stage of the update we update the internals of the data structures at
    #synchronization points within the updates to ensure consistency
    if model_msg.Elements.length > 0
      doModelUpdate()
    else if node_msg.Elements.length > 0
      doNodeUpdate()
    else if link_msg.Elements.length > 0
      doLinkUpdate()

  load: () =>
    ($.get "/addie/"+dsg+"/design/read", (data, status, jqXHR) =>
      console.log("design read success")
      console.log(data)
      @doLoad(data)
      true
    ).fail (data) =>
      console.log("design read fail " + data.status)

  loadedModels = {}

  loadElements: (elements) =>
    links = []
    plinks = []
    for x in elements
      @ve.namemanager.getName(x.type.toLowerCase())
      switch x.type
        when "Computer"
          @loadComputer(x.object)
        when "Router"
          @loadRouter(x.object)
        when "Switch"
          @loadSwitch(x.object)
        when "Phyo"
          @loadPhyo(x.object)
        when "Sax"
          @loadSax(x.object)
        when "Link"
          links.push(x.object)
        when "Plink"
          plinks.push(x.object)
          @ve.namemanager.getName("link")

    for x in links
      @loadLink(x)
    
    for x in plinks
      @loadPlink(x)

    @ve.render()

    true

  loadModels: (models) =>
    for x in models
      m = @ve.mbox.addElement((box, x, y) -> new BaseElements.Model(box, x, y, 5))
      m.props = x
      m.id.name = x.name
      loadedModels[m.props.name] = m

  doLoad: (m) =>
    @loadModels(m.models)
    @loadElements(m.elements)
    true

  setProps: (x, p) =>
    x.props = p
    x.id.name = p.name
    x.id.sys = p.sys
    x.id.design = p.design

  loadComputer: (x) =>
    c = new BaseElements.Computer(@ve.surface.baseRect,
                                  x.position.x, x.position.y, x.position.z)
    @setProps(c, x)
    @ve.surface.elements.push(c)
    true

  loadPhyo: (x) =>
    p = new BaseElements.Phyo(@ve.surface.baseRect,
                               x.position.x, x.position.y, x.position.z)
    @setProps(p, x)
    @ve.surface.elements.push(p)
    m = loadedModels[p.props.model]
    m.instances.push(p)
    p.model = m
    p.loadArgValues()
    true

  loadSax: (x) =>
    s = new BaseElements.Sax(@ve.surface.baseRect,
                               x.position.x, x.position.y, x.position.z)
    @setProps(s, x)
    @ve.surface.elements.push(s)
    true

  loadRouter: (x) =>
    r = new BaseElements.Router(@ve.surface.baseRect,
                                x.position.x, x.position.y, x.position.z)

    @setProps(r, x)
    @ve.surface.elements.push(r)
    true

  loadSwitch: (x) =>
    s = new BaseElements.Switch(@ve.surface.baseRect,
                                x.position.x, x.position.y, x.position.z)

    @setProps(s, x)
    @ve.surface.elements.push(s)
    true

  loadLink: (x) =>
    a = @ve.surface.getElement(
      x.endpoints[0].name,
      x.endpoints[0].sys
    )
    if a == null
      console.log("bad endpoint detected")

    b = @ve.surface.getElement(
      x.endpoints[1].name,
      x.endpoints[1].sys
    )
    if b == null
      console.log("bad endpoint detected")

    l = new BaseElements.Link(@ve.surface.baseRect,
          a.shp.obj3d.linep, b.shp.obj3d.linep, 0, 0, 5)

    a.links.push(l)
    a.shp.obj3d.lines.push(l.ln)
    b.links.push(l)
    b.shp.obj3d.lines.push(l.ln)

    l.endpoint[0] = a
    l.endpoint[1] = b
    l.ep_ifx[0] = x.endpoints[0].ifname
    l.ep_ifx[1] = x.endpoints[1].ifname

    @setProps(l, x)
    l.setEndpointData()
    @ve.surface.elements.push(l)
    true

  #grosspants
  loadPlink: (x) =>
    a = @ve.surface.getElement(
      x.endpoints[0].name,
      x.endpoints[0].sys
    )
    if a == null
      console.log("bad endpoint detected")

    b = @ve.surface.getElement(
      x.endpoints[1].name,
      x.endpoints[1].sys
    )
    if b == null
      console.log("bad endpoint detected")

    l = new BaseElements.Link(@ve.surface.baseRect,
          a.shp.obj3d.linep, b.shp.obj3d.linep, 0, 0, 5)

    a.links.push(l)
    a.shp.obj3d.lines.push(l.ln)
    b.links.push(l)
    b.shp.obj3d.lines.push(l.ln)

    l.endpoint[0] = a
    l.endpoint[1] = b
    #l.ep_ifx[0] = x.endpoints[0].ifname
    #l.ep_ifx[1] = x.endpoints[1].ifname

    l.applyPhysicalProps()
    @setProps(l, x)
    l.unpackBindings()
    l.setEndpointData()
    @ve.surface.elements.push(l)
    true

  analyze: () =>
    console.log("asking addie to analyze the design")


class EBoxSelectHandler
  constructor: (@mh) ->

  test: (ixs) ->
    ixs.length > 2 and
    ixs[ixs.length - 2].object.userData instanceof StaticElementBox and
    ixs[0].object.userData.cyjs?

  handleDown: (ixs) ->
    e = ixs[0].object.userData
    console.log "! ebox select -- " + e.constructor.name
    console.log e
    #TODO double click should lock linking until link icon clicked again
    #     this way many things may be linked without going back to the icon
    if e instanceof Link
      console.log "! linking objects"
      @mh.ve.container.onmousemove = (eve) => @mh.linkingH.handleMove0(eve)
      @mh.ve.container.onmousedown = (eve) => @mh.linkingH.handleDown0(eve)
    else
      console.log "! placing objects"
      @mh.makePlacingObject(e)
      @mh.ve.container.onmousemove = (eve) => @handleMove(eve)
      @mh.ve.container.onmouseup = (eve) => @handleUp(eve)

  handleUp: (event) ->
    @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
    @mh.ve.addie.update([@mh.placingObject])

    @mh.ve.container.onmousemove = null
    @mh.ve.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.ve.container.onmouseup = null

  handleMove: (event) ->
    @mh.updateMouse(event)

    @mh.ve.raycaster.setFromCamera(@mh.pos, @mh.ve.camera)
    bix = @mh.ve.raycaster.intersectObject(@mh.ve.surface.baseRect.obj3d)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      @mh.ve.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      @mh.ve.render()

class MBoxSelectHandler
  constructor: (@mh) ->
    @model = null
    @instance = null


  test: (ixs) ->
    ixs.length > 2 and
    ixs[ixs.length - 2].object.userData instanceof ModelBox and
    ixs[0].object.userData.cyjs?
  
  handleDown: (ixs) ->
    e = ixs[0].object.userData
    @mh.ve.surface.clearSelection()
    @model = e

    console.log('mbox down')
    @mh.ve.container.onmousemove = (eve) => @handleMove0(eve)
    @mh.ve.container.onmouseup = (eve) => @handleUp(eve)
  
  handleUp: (event) ->
    console.log('mbox up')

    if @instance?
      @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
      @mh.placingObject.sync()
      @mh.ve.addie.update([@mh.placingObject])
      @mh.ve.surface.clearSelection()

    if !@instance?
      @mh.ve.equationEditor.show(@model)
      @mh.ve.propsEditor.elements = [@model]
      @mh.ve.propsEditor.show()

    @mh.ve.container.onmousemove = null
    @mh.ve.container.onmouseup = null
    @instance = null
  
  handleMove0: (event) ->
    #console.log('mbox move0')
    @instance = @mh.makePlacingObject(@model.instantiate(null, 0, 0, 0, 25, 25))
    #@instance.props.model = @model.props.name
    @instance.model = @model
    @instance.addArgs()
    @model.instances.push(@instance)
    @mh.ve.container.onmousemove = (eve) => @handleMove1(eve)

  handleMove1: (event) ->
    #console.log('mbox move1')
    @mh.updateMouse(event)
    @mh.ve.propsEditor.hide()
    @mh.ve.equationEditor.hide()
    @mh.ve.surface.clearSelection()

    @mh.ve.raycaster.setFromCamera(@mh.pos, @mh.ve.camera)
    bix = @mh.ve.raycaster.intersectObject(@mh.ve.surface.baseRect.obj3d)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      @mh.ve.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      @mh.ve.render()

class SurfaceElementSelectHandler
  constructor: (@mh) ->
    @start = new THREE.Vector3(0,0,0)
    @end= new THREE.Vector3(0,0,0)

  test: (ixs) ->
    ixs.length > 1 and
    ixs[ixs.length - 1].object.userData instanceof Surface and
    ixs[0].object.userData.cyjs?

  handleDown: (ixs) ->
    @mh.updateMouse(event)
    @start.copy(@mh.pos)
    e = ixs[0].object.userData
    console.log "! surface select -- " + e.constructor.name
    @mh.ve.surface.clearSelection()
    @mh.ve.surface.selectObj(e)
    @mh.ve.propsEditor.elements = [e]
    @mh.ve.propsEditor.show()

    #if e instanceof BaseElements.Model
    #  @mh.ve.equationEditor.show(e)

    @mh.placingObject = e
    @mh.ve.container.onmouseup = (eve) => @handleUp(eve)
    @mh.ve.container.onmousemove = (eve) => @handleMove(eve)
  
  handleUp: (ixs) ->
    @mh.updateMouse(event)
    @end.copy(@mh.pos)
    if @mh.placingObject.shp?
      @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
      if @start.distanceTo(@end) > 0
        @mh.ve.addie.update([@mh.placingObject])

    @mh.ve.container.onmousemove = null
    @mh.ve.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.ve.container.onmouseup = null
  
  handleMove: (event) ->
    @mh.updateMouse(event)

    @mh.ve.raycaster.setFromCamera(@mh.pos, @mh.ve.camera)
    bix = @mh.ve.raycaster.intersectObject(@mh.ve.surface.baseRect.obj3d)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      @mh.ve.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      @mh.ve.render()


#TODO, me thinks that react.js orangular.js is meant to deal with precisely 
#the problem we are tyring to solve with the props editor, in the future we 
#should look into replacing dat.gui (as nifty as it is) with an angular 
#based control that is a bit more intelligent
class PropsEditor
  constructor: (@ve) ->
    @elements = []
    @cprops = {}

  show: () ->
    for e in @elements
      e.sync() if e.sync?

    @commonProps()
    @datgui = new dat.GUI()
    for k, v of @cprops
      @datgui.add(@cprops, k)
    true

  save: () ->
      for k, v of @cprops
        for e in @elements
          e.props[k] = v if v != "..."
          e.sync() if e.sync?
      @ve.addie.update(@elements)

  hide: () ->
    if @datgui?
      @save()
      @datgui.destroy()
      @elements = []
      @cprops = {}
      @datgui = null

  commonProps: () ->
    
    ps = {}
    cps = new Array()

    addProp = (d, k, v) ->
      if !d[k]?
        d[k] = [v]
      else
        d[k].push(v)

    addProps = (e) =>
      for k, v of e.props
        continue if k == 'position'
        continue if k == 'design'
        continue if k == 'endpoints'
        continue if k == 'interfaces'
        continue if k == 'path'
        continue if k == 'args'
        continue if k == 'equations'
        continue if k == 'bindings'
        continue if k == 'name' and @elements.length > 1
        addProp(ps, k, v)

    addProps(e) for e in @elements

    addCommon = (k, v, es) ->
      if v.length == es.length then cps[k] = v
      true

    addCommon(k, v, @elements) for k, v of ps

    isUniform = (xs) ->
      u = true
      i = xs[0]
      for x in xs
        u = (x == i)
        break if !u
      u

    setUniform = (k, v, e) ->
      if isUniform(v)
        e[k] = v[0]
      else
        e[k] = "..."
      true

    reduceUniform = (xps) ->
      setUniform(k, v, xps) for k, v of xps
      true

    reduceUniform(cps)

    @cprops = cps
    cps


class EquationEditor
  constructor: (@ve) ->
    @model = null

  show: (m) ->
    @model = m
    console.log("showing equation editor")
    $("#eqtnSrc").val(@model.props.equations)
    $("#eqtnEditor").css("display", "inline")
  
  hide: () ->
    console.log("hiding equation editor")
    if @model?
      @model.props.equations= $("#eqtnSrc").val()
    $("#eqtnEditor").css("display", "none")



class SurfaceSpaceSelectHandler
  constructor: (@mh) ->
    @selCube = new SelectionCube()

  test: (ixs) ->
    ixs.length > 0 and
    ixs[0].object.userData instanceof Surface

  handleDown: (ixs) ->
    console.log "! space select down"
    p = new THREE.Vector3(
      ixs[ixs.length - 1].point.x,
      ixs[ixs.length - 1].point.y,
      75
    )
    @selCube.init(p)
    @mh.ve.container.onmouseup = (eve) => @handleUp(eve)
    @mh.ve.surface.selectorGroup.add(@selCube.obj3d)
    @mh.ve.container.onmousemove = (eve) => @handleMove(eve)
    @mh.ve.surface.clearSelection()

  handleUp: (event) ->
    console.log "! space select up"
    sel = @mh.ve.surface.getSelection(@selCube.obj3d.geometry.boundingBox)
    @mh.ve.surface.selectObj(o) for o in sel
    @mh.ve.propsEditor.elements = sel
    console.log('common props')
    @mh.ve.propsEditor.show()
    @selCube.reset()
    @mh.ve.container.onmousemove = null
    @mh.ve.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.ve.container.onmouseup = null
    @mh.ve.surface.clearSelector()
    @mh.ve.render()

  handleMove: (event) ->
    bix = @mh.baseRectIx(event)
    if bix.length > 0
      p = new THREE.Vector3(
        bix[bix.length - 1].point.x,
        bix[bix.length - 1].point.y,
        75
      )
      @selCube.update(p)
      @mh.ve.render()
    

class LinkingHandler
  constructor: (@mh) ->

  handleDown0: (event) ->
    @mh.ve.raycaster.setFromCamera(@mh.pos, @mh.ve.camera)
    ixs = @mh.ve.raycaster.intersectObjects(
              @mh.ve.surface.baseRect.obj3d.children)

    if ixs.length > 0 and ixs[0].object.userData.cyjs?
      e = ixs[0].object.userData
      console.log "! link0 " + e.constructor.name
      pos0 = ixs[0].object.linep
      pos1 = new THREE.Vector3(
        ixs[0].object.position.x,
        ixs[0].object.position.y,
        5
      )

      @mh.placingLink = new BaseElements.Link(@mh.ve.surface.baseRect,
        pos0, pos1, 0, 0, 5
      )
      @mh.ve.surface.elements.push(@mh.placingLink)
      @mh.placingLink.props.name = @mh.ve.namemanager.getName("link")
      @mh.placingLink.id.name = @mh.placingLink.props.name
      
      ifname = ""
      if ixs[0].object.userData.props.interfaces?
        ifname = "ifx"+Object.keys(ixs[0].object.userData.props.interfaces).length
        ixs[0].object.userData.props.interfaces[ifname] = {
          name: ifname,
          latency: 0,
          capacity: 1000
        }
      @mh.placingLink.endpoint[0] = ixs[0].object.userData
      @mh.placingLink.ep_ifx[0] = ifname
      @mh.placingLink.endpoint[0].links.push(@mh.placingLink)
      ixs[0].object.lines.push(@mh.placingLink.ln)
      @mh.ve.container.onmousemove = (eve) => @handleMove1(eve)
      @mh.ve.container.onmousedown = (eve) => @handleDown1(eve)
    else
      console.log "! link0 miss"

  handleDown1: (event) ->
    @mh.ve.raycaster.setFromCamera(@mh.pos, @mh.ve.camera)
    ixs = @mh.ve.raycaster.intersectObjects(
                @mh.ve.surface.baseRect.obj3d.children)
    if ixs.length > 0 and ixs[0].object.userData.cyjs?
      e = ixs[0].object.userData
      console.log "! link1 " + e.constructor.name
      @mh.placingLink.ln.geom.vertices[1] = ixs[0].object.linep
      ixs[0].object.lines.push(@mh.placingLink.ln)
      
      ifname = ""
      if ixs[0].object.userData.props.interfaces?
        ifname = "ifx"+Object.keys(ixs[0].object.userData.props.interfaces).length
        ixs[0].object.userData.props.interfaces[ifname] = {
          name: ifname,
          latency: 0,
          capacity: 1000
        }
      @mh.placingLink.endpoint[1] = ixs[0].object.userData
      @mh.placingLink.ep_ifx[1] = ifname
      @mh.placingLink.endpoint[1].links.push(@mh.placingLink)

      @mh.ve.surface.updateLink(@mh.placingLink.ln)
      @mh.placingLink.ifInternetToWanLink()
      @mh.placingLink.ifPhysicalToPlink()
      @mh.placingLink.setEndpointData()

      @mh.ve.addie.update([@mh.placingLink])


      @mh.ve.container.onmousemove = null
      @mh.ve.container.onmousedown = (eve) => @mh.baseDown(eve)
    else
      console.log "! link1 miss"

  handleMove0: (event) ->
    @.mh.updateMouse(event)
    #console.log "! lm0"
    
  handleMove1: (event) ->
    #TODO replace me with baseRectIx when that is ready
    @.mh.updateMouse(event)
    @.mh.ve.raycaster.setFromCamera(@.mh.pos, @.mh.ve.camera)
    bix = @.mh.ve.raycaster.intersectObject(@.mh.ve.surface.baseRect.obj3d)
    if bix.length > 0
      #console.log "! lm1"
      @.mh.ve.scene.updateMatrixWorld()
      @.mh.placingLink.ln.geom.vertices[1].x = bix[bix.length - 1].point.x
      @.mh.placingLink.ln.geom.vertices[1].y = bix[bix.length - 1].point.y
      @.mh.placingLink.ln.geom.verticesNeedUpdate = true
      @.mh.ve.render()

#Mouse handler encapsulates the logic of dealing with mouse events
class MouseHandler

  constructor: (@ve) ->
    @pos = new THREE.Vector3(0, 0, 1)
    @eboxSH = new EBoxSelectHandler(this)
    @mboxSH = new MBoxSelectHandler(this)
    @surfaceESH = new SurfaceElementSelectHandler(this)
    @surfaceSSH = new SurfaceSpaceSelectHandler(this)
    @linkingH = new LinkingHandler(this)

  ondown: (event) -> @baseDown(event)
  
  updateMouse: (event) ->
    @pos.x =  (event.layerX / @ve.container.offsetWidth ) * 2 - 1
    @pos.y = -(event.layerY / @ve.container.offsetHeight) * 2 + 1
    #console.log(@pos.x + "," + @pos.y)

  baseRectIx: (event) ->
    @updateMouse(event)
    @ve.raycaster.setFromCamera(@pos, @ve.camera)
    @ve.raycaster.intersectObject(@ve.surface.baseRect.obj3d)

  placingObject: null
  placingLink: null
  
  makePlacingObject: (obj) ->
    @ve.raycaster.setFromCamera(@pos, @ve.camera)
    bix = @ve.raycaster.intersectObject(@ve.surface.baseRect.obj3d)
    x = y = 0
    if bix.length > 0
      ix = bix[bix.length - 1]
      x = ix.point.x
      y = ix.point.y

    @placingObject = @ve.surface.addElement(obj, x, y)

  #onmousedown handlers
  baseDown: (event) ->

    #the order actually matters here, need to hide the equation editor first
    #so the equations get saved to the underlying object before the props
    #editor sends them to addie
    @ve.equationEditor.hide()
    @ve.propsEditor.hide()

    #get the list of objects the mouse click intersected
    #@ve.scene.updateMatrixWorld()
    @updateMouse(event)
    @ve.raycaster.setFromCamera(@pos, @ve.camera)
    ixs = @ve.raycaster.intersectObjects(@ve.scene.children, true)

    #delegate the handling of the event to one of the handlers
    if      @eboxSH.test(ixs) then @eboxSH.handleDown(ixs)
    else if @mboxSH.test(ixs) then @mboxSH.handleDown(ixs)
    else if @surfaceESH.test(ixs) then @surfaceESH.handleDown(ixs)
    else if @surfaceSSH.test(ixs) then @surfaceSSH.handleDown(ixs)

    true



