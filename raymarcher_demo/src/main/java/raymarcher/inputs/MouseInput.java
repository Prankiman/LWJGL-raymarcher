package raymarcher.inputs;

import org.lwjgl.glfw.GLFWCursorPosCallback;

import raymarcher.window.Window;

public class MouseInput extends GLFWCursorPosCallback{

    double oldx, oldy;

    @Override
    public void invoke(long window, double xpos, double ypos) {

        Window.dx += (float) (xpos-oldx)*5;
        Window.dy += (float)(ypos-oldy)*5;
        oldy = ypos;
        oldx = xpos;
        

    }
    
}
