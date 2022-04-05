package raymarcher.inputs;

import org.lwjgl.glfw.GLFWCursorPosCallback;

import raymarcher.window.Window;

public class MouseInput extends GLFWCursorPosCallback{

    double oldx, oldy;
    int s = 0;
    @Override
    public void invoke(long window, double xpos, double ypos) {
        
        s++;

        Window.dx += (float) (xpos-oldx);
        Window.dy += (float)(ypos-oldy);
        if(s%5 == 0){
            oldy = ypos;
            oldx = xpos;
        }

    }
    
}
