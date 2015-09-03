root = exports ? this

getParameterByName = (name) =>
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
    results = regex.exec(location.search)
    decodeURIComponent(results[1].replace(/\+/g, " "))

initViz = () =>
  g.ve = new VisualEnvironment(
    document.getElementById("surface0"),
    document.getElementById("surface1"),
    document.getElementById("surface2"),
    document.getElementById("surface3"),
    document.getElementById("controlPanel")
  )
  g.ve.ebox = new StaticElementBox(g.ve, 120, g.ve.cheight/2 - 65)
  mh = g.ve.cheight - 167
  g.ve.mbox = new ModelBox(g.ve, mh, (g.ve.cheight - 140)/2 - mh/2.0 - 60)
  #g.ve.surface = new Surface(g.ve)
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
    #g.ve.addie.load()
    g.ve.addie.init()
    true
  ).fail () ->
    console.log("fail to get current user, going back to login screen")
    window.location.href = location.origin
    true

#Global event handlers
root.vz_mousedown = (event, idx) ->
  #g.ve.mouseh.ondown(event)
  #g.ve.sview = g.ve.surfaceViews[idx]
  #g.ve.surfaceViews[idx].mouseh.ondown(event)
  g.ve.sview.mouseh.ondown(event)

root.hsplit_mdown = (event) =>
  g.ve.splitView.hdown(event)

root.vsplit_mdown = (event) =>
  g.ve.splitView.vdown(event)

root.vz_keydown = (event) =>
  #g.ve.keyh.ondown(event)
  g.ve.sview.keyh.ondown(event)

root.vz_wheel = (event, idx) =>
  #g.ve.mouseh.onwheel(event)
  #g.ve.sview = g.ve.surfaceViews[idx]
  g.ve.sview.mouseh.onwheel(event)

root.run = (event) =>
  g.ve.addie.run()

root.materialize = (event) =>
  g.ve.addie.materialize()

root.newModel = (event) ->
  g.ve.mbox.newModel()

root.compile = () =>
  g.ve.addie.compile()

root.showSimSettings = () =>
  g.ve.showSimSettings()

root.showDiagnostics = () =>
  g.ve.showDiagnostics()

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
      @material = new THREE.LineBasicMaterial(
        {color: color, linewidth: 3, transparent: false, opacity: 0.7}
      )
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
          color: 0xFDBF3B,
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
    
  setSshCmd: (x) =>
    x.props.sshcmd =
      'ssh -A -t '+g.user+'@users.isi.deterlab.net '+
      'ssh -A '+x.props.name+'.'+g.user+'-'+dsg+'.cypress'
 
  #The Computer class is a representation of a computer
  Computer: class Computer
    constructor: (@parent, x, y, z) ->
      @shp = new Shapes.Diamond(0x2390ff, x, y, z, 15)
      @shp.obj3d.userData = this
      @parent.obj3d.add(@shp.obj3d)
      @props = {
        name: "computer0",
        sys: "root",
        os: "Ubuntu1404-54-STD",
        start_script: "",
        interfaces: {},
        sshcmd: ""
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
        model: "",
        args: "",
        init: ""
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
      @ln = new Shapes.Line(0x5f5f5f, from, to, z)
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

    removePhantomEndpoint: (i) ->
      if @endpoint[i] instanceof Sax
        delete @endpoint[i].props.interfaces[@ep_ifx[i]]

    ifPhysicalToPlink: ->
      if @isPhysical()
        @removePhantomEndpoint(0)
        @removePhantomEndpoint(1)
        @applyPhysicalProps()
    
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
    @x = -@ve.cwidth/2  + @width / 2 + 5
    #@x = 0
    #@y =  0
    @z = 5
    @box = new Shapes.Rectangle(0x404040, @x, @y, @z, @width, @height)
    @box.obj3d.userData = this
    @ve.sscene.add(@box.obj3d)
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
    #@height = @ve.l
    #@width = @ve.l
    @width = 5000
    @height = 5000
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

  removeElement: (e) =>
    idx = @elements.indexOf(e)
    if idx > -1
      @elements.splice(idx, 1)

    obj3d = null
    obj3d = e.shp.obj3d if e.shp?
    obj3d = e.ln.obj3d if e.ln?
    idx = @baseRect.obj3d.children.indexOf(obj3d)
    if idx > -1
      @baseRect.obj3d.children.splice(idx, 1)

    if e.glowBubble?
      idx = @selectGroup.children.indexOf(e.glowBubble)
      if idx > -1
        @selectGroup.children.splice(idx, 1)
      delete e.glowBubble

    @ve.render()

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
    if o.linep?
      o.linep.x = p.x
      o.linep.y = p.y

    if o.userData.glowBubble?
      o.userData.glowBubble.position.x = p.x
      o.userData.glowBubble.position.y = p.y

    if o.lines?
      @updateLink(ln) for ln in o.lines
    true

  moveObjectRelative: (o, p) ->
    o.position.x += p.x
    o.position.y += p.y
    if o.linep?
      o.linep.x += p.x
      o.linep.y += p.y

    ###
    if o.userData.glowBubble?
      o.userData.glowBubble.position.x += p.x
      o.userData.glowBubble.position.y += p.y
    ###

    if o.lines?
      @updateLink(ln) for ln in o.lines
    true

  
  glowMaterial: () ->
    #cam = @ve.sview.camera
    new THREE.ShaderMaterial({
      uniforms: {
          "c": { type: "f", value: 1.0 },
          "p": { type: "f", value: 1.4 },
          glowColor: { type: "c", value: new THREE.Color(0xFDBF3B) },
          viewVector: { type: "v3", value: new THREE.Vector3(0, 0, 200) }
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

      ###
      if obj.shp?
        @selectGroup.add(obj.shp.obj3d)
      if obj.ln?
        @selectGroup.add(obj.ln.obj3d)
      ###
      
      @ve.render()
    true

  clearSelection: (clearProps = true) ->

    #delete gb.userData.glowBubble for gb in @selectGroup.children

    for x in @selectGroup.children
      if x.userData.glowBubble?
        delete x.userData.glowBubble
        #@baseRect.obj3d.children.push(x)

    @selectGroup.children = []
    @clearPropsGUI() if clearProps
    @ve.render()

  clearSelector: ->
    @selectorGroup.children = []
    @ve.render()

  deleteSelection: () =>
    console.log("deleting selection")
    deletes = []
    for x in @selectGroup.children
      deletes.push(x.userData)
      if x.userData.links?
        deletes.push.apply(deletes, x.userData.links)
    @ve.addie.delete(deletes)

    for d in deletes
      @removeElement(d)

    @ve.propsEditor.hide(false)
    @ve.equationEditor.hide()
    true

class NameManager
  constructor: (@ve) ->
    @names = new Array()

  getName: (s, sys='root') ->
    n = ""
    if !@names[s]?
      @names[s] = 0
      n = s + @names[s]
    else
      @names[s]++
      n = s + @names[s]
      while @ve.surface.getElement(n, sys) != null
        @names[s]++
        n = s + @names[s]

    #s + @names[s]
    n

class SimSettings
  constructor: () ->
    @props = {
      begin: 0,
      end: 0,
      maxStep: 1e-3
    }

#VisualEnvironment holds the state associated with the Threejs objects used
#to render Surfaces and the ElementBox. This class also contains methods
#for controlling and interacting with this group of Threejs objects.
class VisualEnvironment

  #Constructs a visual environment for the given @container. @container must
  #be a reference to a <div> dom element. The Threejs canvas the visual 
  #environment renders onto will be appended as a child of the supplied 
  #container
  constructor: (@sc0, @sc1, @sc2, @sc3, @scontainer) ->
    @scene = new THREE.Scene()
    @sscene = new THREE.Scene()
    @surface = new Surface(this)
    #@surfaceViews[1].renderer.setClearColor(0x363636, 1)
    #@width = @container.offsetWidth
    #@height = @container.offsetHeight
    @cwidth = @scontainer.offsetWidth #200
    @cheight = @scontainer.offsetHeight
    
    #@l = Math.max(@width, @height)
    #@l = 2000
    ###
    @camera = new THREE.OrthographicCamera(
      @width / -2, @width / 2,
      @height / 2, @height / -2,
      1, 1000)
    ###
    #@camera = new THREE.OrthographicCamera(
    #  @l/-2, @l/2,
    #  @l/2, @l/-2,
    #  1, 1000)
    @scamera = new THREE.OrthographicCamera(
      @cwidth / -2, @cwidth / 2,
      @cheight / 2, @cheight / -2,
      1, 1000)

    
    @sview = new SurfaceView(this, @sc0)

    @srenderer = new THREE.WebGLRenderer({antialias: true, alpha: true})
    @srenderer.setSize(@cwidth, @cheight)
    @clear = 0x262626
    @alpha = 1
    @srenderer.setClearColor(@clear, @alpha)
    @scontainer.appendChild(@srenderer.domElement)
    #@camera.position.z = 200
    #@camera.zoom = 1
    @scamera.position.z = 200
    @scamera.zoom = 1
    #@mouseh = new MouseHandler(this)
    @keyh = new KeyHandler(this)
    #@raycaster = new THREE.Raycaster()
    #@raycaster.linePrecision = 10
    @namemanager = new NameManager(this)
    #@xpcontrol = new ExperimentControl(this)
    @addie = new Addie(this)
    @propsEditor = new PropsEditor(this)
    @equationEditor = new EquationEditor(this)
    @simSettings = new SimSettings()
    @splitView = new SplitView(this)

  hsplit: () =>
    console.log("hsplit")
  
  vsplit: () =>
    console.log("vsplit")

  render: ->
    #sv.doRender() for sv in @surfaceViews
    @sview.doRender()
    #@renderer.clear()
    #@renderer.clearDepth()
    #@renderer.render(@scene, @camera)
    
    @srenderer.clear()
    @srenderer.clearDepth()
    @srenderer.render(@sscene, @scamera)

  showSimSettings: () ->
    @propsEditor.hide()
    @propsEditor.elements = [@simSettings]
    @propsEditor.show()

  showDiagnostics: () =>
    console.log("Showing Diagnostics")
    h = window.innerHeight

    dh = parseInt($("#diagnosticsPanel").css("height").replace('px', ''))
    if dh > 0
      $("#diagnosticsPanel").css("top", h+"px")
      $("#hsplitter").css("top", "auto")
    else
      $("#diagnosticsPanel").css("top", (h-200)+"px")
      $("#hsplitter").css("top", (h-205)+"px")
      $("#diagnosticsPanel").css("height", "auto")



class SplitView
  constructor: (@ve) ->
    @c0 = window.innerWidth
    @c1 = @c0

  splitRatio: () ->
    @c0 / window.innerWidth
    

  hdown: (event) =>
    $("#metasurface").mouseup(@hup)
    $("#diagnosticsPanel").mouseup(@hup)
    $("#metasurface").mousemove(@hmove)
    $("#diagnosticsPanel").mousemove(@hmove)
    $("#diagnosticsPanel").css("height", "auto")

  hup: (event) =>
    console.log("hup")
    $("#metasurface").off('mousemove')
    $("#metasurface").off('mouseup')
    $("#diagnosticsPanel").off('mousemove')
    $("#diagnosticsPanel").off('mouseup')

  hmove: (event) =>
    $("#diagnosticsPanel").css("top", (event.clientY+5)+"px")
    $("#hsplitter").css("top", event.clientY+"px")






  vdown: (event) =>
    $("#metasurface").mouseup(@vup)
    $("#metasurface").mousemove(@vmove)

  vup: (event) =>
    console.log("vup")
    $("#metasurface").off('mousemove')
    $("#metasurface").off('mouseup')
    @ve.render()

  vmove: (event) =>
    @c1 = event.clientX
    dc = @c1 - @c0
    x = @c1+"px"
    r = ($("#metasurface").width() - @c1)+"px"
    $("#vsplitter").css("left", x)

    left = 0
    center = event.clientX
    right = window.innerWidth

    @ve.sview.panes[0].viewport.width = center - left
    @ve.sview.panes[1].viewport.width = right - center
    @ve.sview.panes[1].viewport.left = center

    @ve.sview.panes[0].camera.right += dc
    @ve.sview.panes[1].camera.right -= dc

    @ve.sview.doRender()

    @c0 = @c1

class SurfaceView
  constructor: (@ve, @container) ->
    @scene = @ve.scene
    @surface = @ve.surface
    @cwidth = @container.offsetWidth
    @cheight = @container.offsetHeight

    @l = Math.max(window.innerWidth, window.innerHeight)
    @l = Math.max(@cwidth, @cheight)
    @clear = 0x262626
    @alpha = 1

    @renderer = new THREE.WebGLRenderer({antialias: true, alpha: true})
    @renderer.setSize(@cwidth, @cheight)
    @renderer.setClearColor(@clear, @alpha)
    #@renderer.setPixelRatio(window.devicePixelRatio)

    @mouseh = new MouseHandler(this)
    @keyh = new KeyHandler(this.ve)
    @raycaster = new THREE.Raycaster()
    @raycaster.linePrecision = 10
    @container.appendChild(@renderer.domElement)

    @panes = [
      {
        id: 1,
        zoomFactor: 1,
        background: 0x262626,
        viewport: {
          left: 0,
          bottom: 0,
          width: @cwidth,
          height: @cheight
        },
        camera: new THREE.OrthographicCamera(
          0, @cwidth,
          @cheight, 0,
          1, 1000)
      }
      {
        id: 2,
        zoomFactor: 1,
        background: 0x464646,
        viewport: {
          left: @cwidth,
          bottom: 0,
          width: 0,
          height: @cheight
        },
        camera: new THREE.OrthographicCamera(
          0, 0,
          @cheight, 0,
          1, 1000)
      }
    ]

    for p in @panes
      p.camera.position.z = 200

  ###
  reInitCamera: () ->
    @cwidth = @container.offsetWidth
    @cheight = @container.offsetHeight
    #@l = Math.max(@cwidth, @cheight)
    @renderer.setSize(@l, @l)
    @renderer.setClearColor(@clear, @alpha)
    @camera.left = @l/-2
    @camera.right = @l/2
    @camera.top = @l/2
    @camera.bottom = @l/-2
    @camera.updateProjectionMatrix()
    @doRender()
  ###

  doRender: () ->
    for p in @panes
      vp = p.viewport
      @renderer.setViewport(vp.left, vp.bottom, vp.width, vp.height)
      @renderer.setScissor(vp.left, vp.bottom, vp.width, vp.height)
      @renderer.enableScissorTest(true)
      @renderer.setClearColor(p.background)
      p.camera.updateProjectionMatrix()
      @renderer.clear()
      @renderer.clearDepth()
      @renderer.render(@scene, p.camera)

  render: () ->
    @ve.render()
  
  getPane: (c) =>
    result = {}
    for p in @panes
      if c.x > p.viewport.left and
         c.x < p.viewport.left + p.viewport.width and
         c.y > p.viewport.bottom and
         c.y < p.viewport.bottom + p.viewport.height

          result = p
          break

    p
         
  
  zoomin: (x = 3, p = new THREE.Vector2(0,0)) ->
    w = Math.abs(@mouseh.icam.right - @mouseh.icam.left)
    h = Math.abs(@mouseh.icam.top - @mouseh.icam.bottom)
    @mouseh.apane.zoomFactor -= x/(@mouseh.apane.viewport.width)
    @mouseh.icam.left += x * (p.x/w)
    @mouseh.icam.right -= x * (1 - p.x/w)
    @mouseh.icam.top -= x * (p.y/h)
    @mouseh.icam.bottom += x * (1 - p.y/h)
    @mouseh.icam.updateProjectionMatrix()
    @render()

  pan: (dx, dy) =>
    @mouseh.icam.left += dx
    @mouseh.icam.right += dx
    @mouseh.icam.top += dy
    @mouseh.icam.bottom += dy
    @mouseh.icam.updateProjectionMatrix()
    @render()


#This is the client side Addie, it talks to the Addie at cypress.deterlab.net
#to manage a design
class Addie
  constructor: (@ve) ->
    @mstate = {
      up: false
    }

  init: () =>
    @load()
    @msync()

  update: (xs) =>
    console.log("updating objects")
    console.log(xs)

    #build the update sets
    link_updates = {}
    node_updates = {}
    model_updates = {}
    settings_updates = []

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

      if x instanceof SimSettings
        settings_updates.push(x)

      true

    #build the update messages
    model_msg = { Elements: [] }
    node_msg = { Elements: [] }
    link_msg = { Elements: [] }
    settings_msg = { Elements: [] }

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

    for s in settings_updates
      settings_msg.Elements.push(
        {
          OID: { name: "", sys: "", design: dsg },
          Type: "SimSettings", Element: s.props
        }
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

    doSettingsUpdate = () =>
      console.log("settings update")
      console.log(settings_msg)

      if settings_msg.Elements.length > 0
        $.post "/addie/"+dsg+"/design/update", JSON.stringify(settings_msg),
          (data) =>
            console.log("settings update complete")


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

    #settings update is independent of other updates so we can break out of the
    #above update structure
    doSettingsUpdate()

  delete: (xs) =>

    console.log("addie deleting objects")
    console.log(xs)

    ds = []

    for x in xs
      if x instanceof Phyo
        ds.push({type: "Phyo", element: x.props})
      if x instanceof Computer
        ds.push({type: "Computer", element: x.props})
      if x instanceof Router
        ds.push({type: "Router", element: x.props})
      if x instanceof Switch
        ds.push({type: "Switch", element: x.props})
      if x instanceof Sax
        ds.push({type: "Sax", element: x.props})
      if x instanceof Link
        if x.isPhysical()
          ds.push({type: "Plink", element: x.props})
        else
          ds.push({type: "Link", element: x.props})
    
    delete_msg = { Elements: ds }


    $.post "/addie/"+dsg+"/design/delete", JSON.stringify(delete_msg),
      (data) =>
        console.log("addie delete complete")
        console.log(data)

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

    for k, v of @ve.namemanager.names
      @ve.namemanager.names[k] = v + 10

    @ve.render()

    true

  loadModels: (models) =>
    for x in models
      m = @ve.mbox.addElement((box, x, y) -> new BaseElements.Model(box, x, y, 5))
      m.props = x
      m.id.name = x.name
      loadedModels[m.props.name] = m

  loadSimSettings: (settings) =>
    @ve.simSettings.props = settings

  doLoad: (m) =>
    @loadModels(m.models)
    @loadElements(m.elements)
    @loadSimSettings(m.simSettings)
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
    BaseElements.setSshCmd(c)
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
    BaseElements.setSshCmd(s)
    @ve.surface.elements.push(s)
    true

  loadRouter: (x) =>
    r = new BaseElements.Router(@ve.surface.baseRect,
                                x.position.x, x.position.y, x.position.z)

    @setProps(r, x)
    BaseElements.setSshCmd(r)
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

  levelColor: (l) =>
    switch l
      when "info" then "blue"
      when "warning" then "orange"
      when "error" then "red"
      when "success" then "green"
      else "gray"

  compile: () =>
   console.log("asking addie to compile the design")
   $("#diagText").html("")
   $("#ajaxLoading").css("display", "block")
   $.get "/addie/"+dsg+"/design/compile", (data) =>
     console.log("compilation result:")
     console.log(data)
     $("#ajaxLoading").css("display", "none")
     if data.elements?
      for d in data.elements
        $("#diagText").append(
          "<span style='color:"+@levelColor(d.level)+"'><b>"+
              d.level+
          "</b></span> - " + d.message + "<br />"
        )


  run: () =>
    console.log("asking addie to run the experiment")
    $.get "/addie/"+dsg+"/design/run", (data) =>
      console.log("run result: ")
      console.log(data)
    #window.open(location.origin + "/results.html?xp=" + dsg)

  materialize: () =>
    if @mstate.up
      console.log("asking addie to dematerialize the experiment")
      $("#materialize").html("Materialize")
      #TODO do an async call here and then grey out the materialization button
      #until the async call returns
      @mstate.up = false
    else
      console.log("asking addie to materialize the experiment")
      $("#materialize").html("Dematerialize")
      @mstate.up = true
      ###
      $.get "/addie/"+dsg+"/design/materialize", (data) =>
        console.log("materialize result: ")
        console.log(data)
      ###

  #synchronize materialization status
  msync: () =>
    console.log("synchronizing materialization state with addie")
    $.get "/addie/"+dsg+"/design/mstate", (data) =>
      console.log("materialization state:")
      console.log(data)
      if data.Status? and data.Status == "Active"
        @mstate.up = true
        $("#materialize").html("Dematerialize")



class EBoxSelectHandler
  constructor: (@mh) ->

  test: (ixs) ->
    ixs.length > 0 and
    ixs[ixs.length - 1].object.userData instanceof StaticElementBox #and
    #ixs[0].object.userData.cyjs?

  handleDown: (ixs) ->
    @mh.sv.surface.clearSelection()
    if ixs[0].object.userData.cyjs?
      e = ixs[0].object.userData
      console.log "! ebox select -- " + e.constructor.name
      console.log e
      #TODO double click should lock linking until link icon clicked again
      #     this way many things may be linked without going back to the icon
      if e instanceof Link
        console.log "! linking objects"
        @mh.placingObject = null
        @mh.sv.container.onmousemove = (eve) => @mh.linkingH.handleMove0(eve)
        @mh.sv.container.onmousedown = (eve) => @mh.linkingH.handleDown0(eve)
      else
        console.log "! placing objects"
        @mh.makePlacingObject(e)
        @mh.sv.container.onmousemove = (eve) => @handleMove(eve)
        @mh.sv.ve.scontainer.onmouseup = (eve) => @handleUp(eve)
        @mh.sv.container.onmouseup = (eve) => @handleUp(eve)


  stillOnEBox: (event) =>
    @mh.updateMouse(event)
    @mh.sv.raycaster.setFromCamera(@mh.spos, @mh.sv.ve.scamera)
    ixs = @mh.sv.raycaster.intersectObjects(@mh.sv.ve.sscene.children, true)
    result = false
    for x in ixs
      if x.object.userData instanceof StaticElementBox
        result = true
        break
    result

  handleUp: (event) ->
    if @stillOnEBox(event)
      @mh.sv.surface.removeElement(@mh.placingObject)
      false
    else
      @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
      @mh.sv.ve.addie.update([@mh.placingObject])

    @mh.sv.container.onmousemove = null
    @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.sv.container.onmouseup = null

  handleMove: (event) ->
    @mh.updateMouse(event)

    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    bix = @mh.sv.raycaster.intersectObject(@mh.sv.surface.baseRect.obj3d)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      @mh.sv.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      @mh.sv.render()

class MBoxSelectHandler
  constructor: (@mh) ->
    @model = null
    @instance = null


  test: (ixs) ->
    ixs.length > 0 and
    ixs[ixs.length - 1].object.userData instanceof ModelBox #and
    #ixs[0].object.userData.cyjs?
  
  handleDown: (ixs) ->
    @mh.sv.surface.clearSelection()
    if ixs[0].object.userData.cyjs?
      e = ixs[0].object.userData
      @model = e

      console.log('mbox down')
      @mh.sv.container.onmousemove = (eve) => @handleMove0(eve)
      @mh.sv.ve.scontainer.onmouseup = (eve) => @handleUp(eve)
      @mh.sv.container.onmouseup = (eve) => @handleUp(eve)

  stillOnMBox: (event) =>
    @mh.updateMouse(event)
    @mh.sv.raycaster.setFromCamera(@mh.spos, @mh.sv.ve.scamera)
    ixs = @mh.sv.raycaster.intersectObjects(@mh.sv.ve.sscene.children, true)
    result = false
    for x in ixs
      if x.object.userData instanceof ModelBox
        result = true
        break
    result

  
  handleUp: (event) ->
    console.log('mbox up')

    if @instance?
      if @stillOnMBox(event)
        @mh.sv.surface.removeElement(@mh.placingObject)
        idx = @model.instances.indexOf(@instance)
        if idx > -1
          @model.instances.splice(idx, 1)
        @instance = null
        @mh.placingObject = null
        false
      else
        @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
        @mh.placingObject.sync()
        @mh.sv.ve.addie.update([@mh.placingObject])
        @mh.sv.surface.clearSelection()

    else if !@instance?
      @mh.sv.ve.propsEditor.elements = [@model]
      @mh.sv.ve.propsEditor.show()
      @mh.sv.ve.equationEditor.show(@model)

    @mh.sv.container.onmousemove = null
    @mh.sv.container.onmouseup = null
    @mh.sv.ve.scontainer.onmouseup = (eve) => null
    @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    @instance = null
  
  handleMove0: (event) ->
    #console.log('mbox move0')
    @instance = @mh.makePlacingObject(@model.instantiate(null, 0, 0, 0, 25, 25))
    #@instance.props.model = @model.props.name
    @instance.model = @model
    @instance.addArgs()
    @model.instances.push(@instance)
    @mh.sv.container.onmousemove = (eve) => @handleMove1(eve)

  handleMove1: (event) ->
    #console.log('mbox move1')
    @mh.updateMouse(event)
    @mh.sv.ve.propsEditor.hide()
    @mh.sv.ve.equationEditor.hide()
    @mh.sv.surface.clearSelection()

    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    bix = @mh.sv.raycaster.intersectObject(@mh.sv.surface.baseRect.obj3d)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      @mh.sv.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      @mh.sv.render()

class SurfaceElementSelectHandler
  constructor: (@mh) ->
    @start = new THREE.Vector3(0,0,0)
    @end= new THREE.Vector3(0,0,0)

    @p0 = new THREE.Vector3(0,0,0)
    @p1 = new THREE.Vector3(0,0,0)

  test: (ixs) ->
    ixs.length > 1 and
    ixs[ixs.length - 1].object.userData instanceof Surface and
    ixs[0].object.userData.cyjs?

  handleDown: (ixs) ->
    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    bix = @mh.sv.raycaster.intersectObject(@mh.sv.surface.baseRect.obj3d)
    @p0.copy(bix[0].point)
    @p1.copy(@p0)

    @mh.updateMouse(event)
    @start.copy(@mh.pos)
    #@last.copy(@mh.pos)
    e = ixs[0].object.userData
    console.log "! surface select -- " + e.constructor.name
    console.log "current selection"
    console.log @mh.sv.surface.selectGroup
    if not ixs[0].object.userData.glowBubble?
      @mh.sv.surface.clearSelection()
    if @mh.sv.surface.selectGroup.children.length == 0
      @mh.sv.ve.propsEditor.elements = [e]
      @mh.sv.ve.propsEditor.show()
    @mh.sv.surface.selectObj(e)

    if e instanceof BaseElements.Phyo
      @mh.sv.ve.equationEditor.show(e.model)

    @mh.placingObject = e
    @mh.sv.container.onmouseup = (eve) => @handleUp(eve)
    @mh.sv.container.onmousemove = (eve) => @handleMove(eve)


  applyGroupMove: () ->
    for x in @mh.sv.surface.selectGroup.children
      #p = @mh.pos.sub(@last)
      p = new THREE.Vector3(@p1.x - @p0.x , @p1.y - @p0.y, @p0.z)
      if x.userData.shp?
        @mh.sv.surface.moveObjectRelative(x.userData.shp.obj3d, p)
      @mh.sv.surface.moveObjectRelative(x, p)
      #x.position.x += @ve.surface.selectGroup.position.x
      #x.position.y += @ve.surface.selectGroup.position.y

  updateGroupMove: () ->
    updates = []
    for x in @mh.sv.surface.selectGroup.children
      x.userData.props.position = x.position
      updates.push(x.userData)
    @mh.sv.ve.addie.update(updates)
      
  
  handleUp: (ixs) ->
    @mh.updateMouse(event)
    @end.copy(@mh.pos)
    if @mh.placingObject.shp?
      @mh.placingObject.props.position = @mh.placingObject.shp.obj3d.position
      if @start.distanceTo(@end) > 0
        #@mh.ve.addie.update([@mh.placingObject])
        @updateGroupMove()

    #@applyGroupMove()
    @mh.sv.container.onmousemove = null
    @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.sv.container.onmouseup = null
  
  handleMove: (event) ->
    @mh.updateMouse(event)

    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    bix = @mh.sv.raycaster.intersectObject(@mh.sv.surface.baseRect.obj3d)
    @p1.copy(bix[0].point)

    if bix.length > 0
      ox = @mh.placingObject.shp.geom.boundingSphere.radius
      #@mh.ve.surface.moveObject(@mh.placingObject.shp.obj3d, bix[0].point)
      #@mh.ve.surface.moveObject(@mh.ve.surface.selectGroup, bix[0].point)
      @applyGroupMove()
      @mh.sv.render()

    #@last.copy(@mh.pos)
    @p0.copy(@p1)

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


    if @elements.length == 1 and @elements[0].funcs?
      for k, v of @elements[0].funcs
        @datgui.add(@elements[0].funcs, k)

    true

  save: () ->
      for k, v of @cprops
        for e in @elements
          e.props[k] = v if v != "..."
          e.sync() if e.sync?
      @ve.addie.update(@elements)

  hide: (doSave = true) ->
    if @datgui?
      @save() if doSave
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
    if @ve.propsEditor.datgui?
      $("#eqtnEditor").css("display", "inline")
      $("#eqtnEditor").css("top",
          @ve.propsEditor.datgui.domElement.clientHeight + 30)
  
  hide: () ->
    console.log("hiding equation editor")
    if @model?
      @model.props.equations= $("#eqtnSrc").val()
    $("#eqtnEditor").css("display", "none")

class PanHandler

  constructor: (@mh) ->
    @p0 = new THREE.Vector2(0,0)
    @p1 = new THREE.Vector2(0,0)
    
  handleDown: (event) =>
    @mh.updateMouse(event)
    @p0.x = event.clientX
    @p0.y = event.clientY
    @p1.x = event.clientX
    @p1.y = event.clientY
    @mh.sv.container.onmouseup = (eve) => @handleUp(eve)
    @mh.sv.container.onmousemove = (eve) => @handleMove(eve)

  handleUp: (event) =>
    @mh.sv.container.onmousemove = null
    @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.sv.container.onmouseup = null

  handleMove: (event) =>
    @p1.x = event.clientX
    @p1.y = event.clientY
    dx = -(@p1.x - @p0.x)
    dx *= @mh.apane.zoomFactor
    dy = @p1.y - @p0.y
    dy *= @mh.apane.zoomFactor
    @mh.sv.pan(dx, dy)
    @p0.x = @p1.x
    @p0.y = @p1.y

class SurfaceSpaceSelectHandler
  constructor: (@mh) ->
    @selCube = new SelectionCube()

  test: (ixs) ->
    ixs.length > 0 and
    ixs[0].object.userData instanceof Surface

  handleDown: (ixs) ->
    @mh.sv.surface.clearSelection()
    console.log "! space select down"
    p = new THREE.Vector3(
      ixs[ixs.length - 1].point.x,
      ixs[ixs.length - 1].point.y,
      75
    )
    @selCube.init(p)
    @mh.sv.container.onmouseup = (eve) => @handleUp(eve)
    @mh.sv.surface.selectorGroup.add(@selCube.obj3d)
    @mh.sv.container.onmousemove = (eve) => @handleMove(eve)
    @mh.sv.surface.clearSelection()

  handleUp: (event) ->
    console.log "! space select up"
    sel = @mh.sv.surface.getSelection(@selCube.obj3d.geometry.boundingBox)
    @mh.sv.surface.selectObj(o) for o in sel
    @mh.sv.ve.propsEditor.elements = sel
    console.log('common props')
    @mh.sv.ve.propsEditor.show()
    @selCube.reset()
    @mh.sv.container.onmousemove = null
    @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    @mh.sv.container.onmouseup = null
    #@mh.ve.surface.clearSelector()
    #@mh.ve.surface.clearSelection()
    @mh.sv.render()

  handleMove: (event) ->
    bix = @mh.baseRectIx(event)
    if bix.length > 0
      p = new THREE.Vector3(
        bix[bix.length - 1].point.x,
        bix[bix.length - 1].point.y,
        75
      )
      @selCube.update(p)
      @mh.sv.render()
    

class LinkingHandler
  constructor: (@mh) ->

  handleDown0: (event) ->
    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    ixs = @mh.sv.raycaster.intersectObjects(
              @mh.sv.surface.baseRect.obj3d.children)

    if ixs.length > 0 and ixs[0].object.userData.cyjs?
      e = ixs[0].object.userData
      console.log "! link0 " + e.constructor.name
      pos0 = ixs[0].object.linep
      pos1 = new THREE.Vector3(
        ixs[0].object.position.x,
        ixs[0].object.position.y,
        5
      )

      @mh.placingLink = new BaseElements.Link(@mh.sv.surface.baseRect,
        pos0, pos1, 0, 0, 5
      )
      @mh.sv.surface.elements.push(@mh.placingLink)
      @mh.placingLink.props.name = @mh.sv.ve.namemanager.getName("link")
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
      @mh.sv.container.onmousemove = (eve) => @handleMove1(eve)
      @mh.sv.container.onmousedown = (eve) => @handleDown1(eve)
    else
      console.log "! link0 miss"

  handleDown1: (event) ->
    @mh.sv.raycaster.setFromCamera(@mh.pos, @mh.icam)
    ixs = @mh.sv.raycaster.intersectObjects(
                @mh.sv.surface.baseRect.obj3d.children)
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

      @mh.sv.surface.updateLink(@mh.placingLink.ln)
      @mh.placingLink.ifInternetToWanLink()
      @mh.placingLink.ifPhysicalToPlink()
      @mh.placingLink.setEndpointData()

      @mh.sv.ve.addie.update([@mh.placingLink])


      @mh.sv.container.onmousemove = null
      @mh.sv.container.onmousedown = (eve) => @mh.baseDown(eve)
    else
      console.log "! link1 miss"

  handleMove0: (event) ->
    @mh.updateMouse(event)
    #console.log "! lm0"
    
  handleMove1: (event) ->
    #TODO replace me with baseRectIx when that is ready
    @mh.updateMouse(event)
    @mh.sv.raycaster.setFromCamera(@.mh.pos, @mh.icam)
    bix = @mh.sv.raycaster.intersectObject(@mh.sv.surface.baseRect.obj3d)
    if bix.length > 0
      #console.log "! lm1"
      @mh.sv.scene.updateMatrixWorld()
      @mh.placingLink.ln.geom.vertices[1].x = bix[bix.length - 1].point.x
      @mh.placingLink.ln.geom.vertices[1].y = bix[bix.length - 1].point.y
      @mh.placingLink.ln.geom.verticesNeedUpdate = true
      @mh.sv.render()

#Mouse handler encapsulates the logic of dealing with mouse events
class MouseHandler

  constructor: (@sv) ->
    @pos = new THREE.Vector3(0, 0, 1)
    @spos = new THREE.Vector3(0, 0, 1)
    @eboxSH = new EBoxSelectHandler(this)
    @mboxSH = new MBoxSelectHandler(this)
    @surfaceESH = new SurfaceElementSelectHandler(this)
    @surfaceSSH = new SurfaceSpaceSelectHandler(this)
    @linkingH = new LinkingHandler(this)
    @panHandler = new PanHandler(this)
    @icam = null

  ondown: (event) -> @baseDown(event)

  onwheel: (event) =>
    @apane = @sv.getPane(new THREE.Vector2(event.layerX, event.layerY))
    @icam = @apane.camera
    @sv.zoomin(-event.deltaY / 5, new THREE.Vector2(event.layerX, event.layerY))

  
  updateMouse: (event) ->
    @apane = @sv.getPane(new THREE.Vector2(event.layerX, event.layerY))
    @icam = @apane.camera

    #@pos.x =  (event.layerX / (@sv.cwidth/2) ) * 2 - 1
    #@pos.y = -(event.layerY / @sv.cheight ) * 2 + 1
    if @apane.id == 1
      sr = @sv.ve.splitView.splitRatio()
    else
      sr = 1 - @sv.ve.splitView.splitRatio()

    @pos.x =  ((event.layerX - @apane.viewport.left) / (@sv.cwidth * sr) ) * 2 - 1
    @pos.y = -((event.layerY - @apane.viewport.bottom) / @sv.cheight ) * 2 + 1
    
    @spos.x =  (event.layerX / @sv.ve.scontainer.offsetWidth ) * 2 - 1
    @spos.y = -(event.layerY / @sv.ve.scontainer.offsetHeight) * 2 + 1
    #console.log(@pos.x + "," + @pos.y)

  baseRectIx: (event) ->
    @updateMouse(event)
    @sv.raycaster.setFromCamera(@pos, @icam)
    @sv.raycaster.intersectObject(@sv.ve.surface.baseRect.obj3d)

  placingObject: null
  placingLink: null
  
  makePlacingObject: (obj) ->
    @sv.raycaster.setFromCamera(@pos, @icam)
    bix = @sv.raycaster.intersectObject(@sv.ve.surface.baseRect.obj3d)
    x = y = 0
    if bix.length > 0
      ix = bix[bix.length - 1]
      x = ix.point.x
      y = ix.point.y

    @placingObject = @sv.surface.addElement(obj, x, y)

  #onmousedown handlers
  baseDown: (event) ->

    #the order actually matters here, need to hide the equation editor first
    #so the equations get saved to the underlying object before the props
    #editor sends them to addie
    @sv.ve.equationEditor.hide()
    @sv.ve.propsEditor.hide()

    #get the list of objects the mouse click intersected
    #@ve.scene.updateMatrixWorld()
    @updateMouse(event)
    console.log(@pos)

    #delegate the handling of the event to one of the handlers
    #check the model boxes first

    ###
    @ve.raycaster.setFromCamera(@spos, @ve.scamera)
    sixs = @ve.raycaster.intersectObjects(@ve.sscene.children, true)
    if      @eboxSH.test(sixs) then @eboxSH.handleDown(sixs)
    else if @mboxSH.test(sixs) then @mboxSH.handleDown(sixs)
    else
      @ve.raycaster.setFromCamera(@pos, @ve.sview.camera)
      ixs = @ve.raycaster.intersectObjects(@ve.scene.children, true)

      if @surfaceESH.test(ixs) then @surfaceESH.handleDown(ixs)
      else if @surfaceSSH.test(ixs) then @surfaceSSH.handleDown(ixs)
    ###

    if event.which == 1
      @sv.raycaster.setFromCamera(@spos, @sv.ve.scamera)
      sixs = @sv.raycaster.intersectObjects(@sv.ve.sscene.children, true)
      if      @eboxSH.test(sixs) then @eboxSH.handleDown(sixs)
      else if @mboxSH.test(sixs) then @mboxSH.handleDown(sixs)
      else
        @sv.raycaster.setFromCamera(@pos, @icam)
        ixs = @sv.raycaster.intersectObjects(@sv.scene.children, true)

        if @surfaceESH.test(ixs) then @surfaceESH.handleDown(ixs)
        else if @surfaceSSH.test(ixs) then @surfaceSSH.handleDown(ixs)

    else if event.which = 3
      @panHandler.handleDown(event)

    true

class KeyHandler

  constructor: (@ve) ->

  ondown: (event) =>
    keycode = window.event.keyCode || event.which

    if(keycode == 74)
      @ve.zoomin()
    else if(keycode == 75)
      @ve.zoomout()
    else if(keycode == 72)
      @ve.hsplit()
    else if(keycode == 86)
      @ve.vsplit()
    else if(keycode == 8 || keycode == 46)
      @ve.surface.deleteSelection()
      event.preventDefault()

    

