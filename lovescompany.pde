import processing.video.*;
import java.util.*;


OPC opc;

static final String VIDEO_DIR = "videos/";
static final boolean DEBUG_ORDER = false;
static final boolean DEBUG_WITH_MOUSE = false;
// XXX: size() should probably change if you change these
static final int HEIGHT = 10;
static final int WIDTH = 40;
static final float CROSSFADE_TIME = 1.0;

List<Movie> movies;
Movie current;
Movie next;
float last_timeleft;

void setup()
{
  // preferably a ratio of WIDTH, HEIGHT
  size(400, 100);

  // Connect to the local instance of fcserver. You can change this line to connect to another computer's fcserver
  opc = new OPC(this, "127.0.0.1", 7890);
  opc.setStatusLed(true);
  for (int i = 0; i < 8; i++) {
    //opc.ledGrid(i*50, HEIGHT, 5, width * (0.5 + i) / 8, height/2, width/WIDTH, height/HEIGHT, 3*HALF_PI, true, true);
    opc.ledGrid((7-i)*50, HEIGHT, 5, width * (0.5 + i) / 8, height/2, width/WIDTH, height/HEIGHT, HALF_PI, true, true);
  }
  
  println("LOADING MOVIES...");
  movies = new ArrayList();
  java.io.File folder = new java.io.File(dataPath(VIDEO_DIR));
  String[] filenames = folder.list();
  for (String f : filenames) {
    println(f);
    if (!f.equals(".DS_Store")) {
      Movie m = new Movie(this, VIDEO_DIR+f);
      // This loads the movie into memory? Avoids playback skipping later.
      m.play();
      // Must be while playing, so not after pause()
      m.volume(0);
      // Instantly pause the movie so we can (actually) play it later
      m.pause();
      // Try to put the move back to the beginning, in case it advanced at all
      m.jump(0);
      movies.add(m);
    }
  }
  println("...DONE.");

  current = nextMovie();
  next = null;
}

int curMovieIndex = 0;
Movie nextMovie() {
  Movie m;
  do {
    do {
      if (DEBUG_ORDER) {
        m = movies.get(curMovieIndex);
        curMovieIndex = (curMovieIndex + 1) % movies.size();
      } else {
        m = movies.get(int(random(movies.size())));
      }
      //println("   trying new", m.filename);
    } while (m == current);
    m.play();
    // Needs to be long enough for transition in and out, at least
    if (m.duration() <= 2*CROSSFADE_TIME) {
      m.stop();
      m = null;
    }
  } while (m == null);
  println(m.filename);
  return m;
}

boolean paused = false;
void mouseClicked() {
  if (keyPressed && keyCode == SHIFT && current != null) {
    if (paused) {
      current.play();
    } else {
      current.pause();
    }
    paused = !paused;
  } else if (current != null) {
    // Skip to crossfade to next by jumping towards the end of the current movie
    current.jump(current.duration() - CROSSFADE_TIME);
  }
}
void draw() {
  float timeleft = current.duration() - current.time();
  
  if ((timeleft < 0.01 ||
       // The above test sometimes doesn't trigger, so also complete
       // the switch to next if it exists (we're doing the crossfade)
       // and timeleft is the same as it was during the last draw().
       timeleft == last_timeleft) 
      // The above tests sometimes trigger falsely (when a video is starting??),
      // so only do this if we really have a next movie loaded and running.      
      && next != null) {
    //println("   movie ended", timeleft, last_timeleft);
    // Rewind movie for the next time it comes up in the shuffle
    current.jump(0);
    // And pause it for playing later
    current.pause();
    current = next;
    next = null;
    timeleft = -1;
  } else if (next == null && timeleft < CROSSFADE_TIME) {
    //println("   starting next");
    next = nextMovie();
  }
  // Remember timeleft for next time; see above
  last_timeleft = timeleft;

  image(current.get(), 0, 0, width, height);
  if (next != null) {
    tint(255, (1.0 - timeleft / CROSSFADE_TIME) * 255.0);
    image(next.get(), 0, 0, width, height);
    noTint();
  }
  //println(frameRate);
  
  if (DEBUG_WITH_MOUSE) {
    background(0);
    ellipse(mouseX, mouseY, 50, 50);
  }
}

void movieEvent(Movie m) {
  m.read();
}
