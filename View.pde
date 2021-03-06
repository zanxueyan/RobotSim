import controlP5.*;    // import controlP5 library

class Views {
  
  View TOP, SIDE, FRONT;
  
  ControlP5 cp5;   // controlP5 object
  Chart phiChart, psiChart, thetaChart, arduChart;
  List<Controller> sliders = new ArrayList();

  Views(float scale){
    TOP = new View(2, 120, 150, 120, 300 + scale*ROBOT.frame.length_, 240 + scale*ROBOT.frame.width_, scale);
    SIDE = new View(2, TOP.y+TOP.h-1, TOP.offset_x, TOP.offset_y*0.4+scale*85, TOP.w, TOP.offset_y * 0.7 + scale*85, scale);
    FRONT = new View(TOP.x+TOP.w-1, SIDE.y, TOP.offset_x, SIDE.offset_y, 2*TOP.offset_x + scale*ROBOT.frame.width_, SIDE.h, scale);
    
    cp5 = new ControlP5(Robot.this);  
    cp5.addButton("prev").setPosition(3,22).setSize(38,15);
    cp5.addButton("pause").setPosition(43,22).setSize(38,15);
    cp5.addButton("next").setPosition(83,22).setSize(38,15);
    cp5.addButton("reset").setPosition(123,22).setSize(38,15);
    
    phiChart = makeChart("phi", 0, 0, 180);
    psiChart = makeChart("psi", 1, 0, 180);
    thetaChart = makeChart("theta", 2, -90, 90);
    
    arduChart = makeArduinoChart(cp5);  // cf arduino tab    
  }
  
  void draw(String name){
    background(240);   // background color
    fill(0);
    text(nf(TIME.time,1,2)+" sec", 3, 15);
    text(name, 80, 15);
    TOP.draw();
    SIDE.draw();
    FRONT.draw(); 
    if(cp5!=null){
      phiChart.push("phi", degrees(ROBOT.legs[0].phi));
      psiChart.push("psi", degrees(ROBOT.legs[0].psi));
      thetaChart.push("theta", degrees(ROBOT.legs[0].theta));
      updateArduinoChart(arduChart);  // cf arduino tab
    }
    drawArduino(); // Arduino interface (cf arduino tab)
  }
    
  void removeSliders(){  
    for(Controller c:sliders)
      cp5.remove(c.getName());
    sliders.clear();
  }
  
  void createSliders(Move move){
    if(cp5!=null && sliders.size()==0){
      int i=0, j=0;  // Line & column of sliders
      for(Parameter p:move.parameters.values()){
        Controller c = cp5.addSlider(p.name, p.min, p.max, p.value, 170+j*350, 5+(i++)*17, 280, 15);
        c.getValueLabel().getStyle().margin(0,0,0,3);
        c.getCaptionLabel().getStyle().margin(0,0,0,3);
        c.getCaptionLabel().setColor(0);
        sliders.add(c);
        if(i==6){ j++; i=0;}
      }
    }
  }
    
  Chart makeChart(String name, int n, float min, float max){
    return cp5.addChart(name)
                 .setPosition(FRONT.x+15, TOP.y + n * TOP.h /3)
                 .setSize((int)FRONT.w-30, (int)TOP.h /4)
                 .setRange(min, max)
                 .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
                 .setColorBackground(color(255))
                 .setStrokeWeight(3)
                 .setColorCaptionLabel(color(40))
                 .addDataSet(name);
  }

}


void controlEvent(ControlEvent e) {
  TIME.event(e);
  if(e.getController() instanceof Slider) PLANNER.move.set(e.getName(), e.getValue());
}

List<Drawable> OBJECTS = new ArrayList();
  
abstract class Drawable {
  Drawable(){  OBJECTS.add(this); }  
  abstract void draw(View v);
}

class View {
  
  PGraphics pg;
  float x,y,offset_x,offset_y,w,h, scale;
  
  View(float x, float y, float offset_x, float offset_y, float w, float h, float scale){
    this.pg = createGraphics((int)w, (int)h);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.offset_x = offset_x;
    this.offset_y = offset_y;
    this.scale = scale;
  }
  
  void draw(){
    pg.beginDraw();
    pg.clear(); 
    pg.noFill();
    pg.strokeWeight(1);   
    pg.rect(0,0,w-1,h-1);
    pg.strokeWeight(3);   
    for(Drawable d : OBJECTS)
      d.draw(this);
    pg.endDraw();
    image(pg, x, y);
  }
  
  
  // Drawing functions

  void arc(PVector v, float r, float a1, float a2){
    pg.arc(x(v), y(v), r, r, a1, a2);
  }
  
  void ellipse(PVector v, float r){
    pg.ellipse(x(v), y(v), r, r);
  }
  
  void line(PVector v1, PVector v2){
    pg.line(x(v1), y(v1), x(v2), y(v2));
  }
  
  void rect(PVector v1, PVector v2){
    pg.rect(x(v1), y(v1), x(v2)-x(v1), y(v2)-y(v1));
  }
  
  void triangle(PVector v1, PVector v2, PVector v3){
    pg.triangle(x(v1), y(v1), x(v2), y(v2), x(v3), y(v3));
  }
  
  void point(PVector pt){
    pg.point(x(pt), y(pt));
  }
  
  void grid(float x0, float y0, float angle, float pitch){
    float p = scale*pitch / cos(angle);
    float tan = tan(angle);
    float x = -h + (offset_x+scale*x0-tan*(offset_y+scale*y0) + h) % p;
    float y = -w + (offset_y+scale*y0+tan*(offset_x+scale*x0) + w) % p;
    for(; x<=w+h || y<=w+h ; x+=p, y+=p){
      pg.line(x,0,x+h*tan,h);
      pg.line(0,y,w,y-w*tan);
    }
  }
  
  void cg(PVector cg){
    pg.strokeWeight(1);
    ellipse(cg, 10);
    pg.fill(pg.strokeColor);
    arc(cg, 10, 0, HALF_PI);
    arc(cg, 10, PI, PI + HALF_PI);   
    pg.noFill();
    pg.strokeWeight(3);
  }
  
  
  // Extract coordinates from vectors, according to the current view
  
  float x(PVector v){
    return offset_x + scale * xraw(v);
  }
  
  float y(PVector v){
    return offset_y + scale * yraw(v);
  }
  
  float xraw(PVector v){
    return (this==UI.TOP? v.x : this==UI.SIDE? v.x : v.y);
  }
  
  float yraw(PVector v){
    return (this==UI.TOP? v.y : this==UI.SIDE? -v.z : -v.z);
  }
  
  
  // Style
   
  void setRed(){ 
    pg.stroke(210, 38, 38);
  }
  
  void setGreen(){ 
    pg.stroke(9, 169, 61); 
  }
  
  void stroke(int a, int b, int c){
    pg.stroke(a,b,c);
  }
  
  void stroke(int i){
    pg.stroke(i);
  }
  
  void strokeWeight(float f){
    pg.strokeWeight(f);
  }
  
  void fill(int a, int b, int c, int d){
    pg.fill(a,b,c,d);
  }
  
  void fill(int a, int b, int c){
    pg.fill(a,b,c);
  }
  
  void fill(int i){
    pg.fill(i);
  }
  
  void noFill(){
    pg.noFill();
  }
}