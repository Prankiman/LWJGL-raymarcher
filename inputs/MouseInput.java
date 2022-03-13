package inputs;

import org.lwjgl.glfw.GLFWCursorPosCallback;

import window.Window;

public class MouseInput extends GLFWCursorPosCallback{


    @Override
    public void invoke(long window, double xpos, double ypos) {
        Window.dx = (float)xpos;
        Window.dy = (float)ypos;

    }
    
}
