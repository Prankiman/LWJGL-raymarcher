package inputs;

import static org.lwjgl.glfw.GLFW.*;

import org.lwjgl.glfw.GLFWKeyCallback;

import window.Window;

public class KeyInput extends GLFWKeyCallback{

    @Override
    public void invoke(long window, int key, int scancode, int action, int mods) {
        if(key == GLFW_KEY_W&& action != GLFW_RELEASE){
            Window.camz += 0.01;
        }
        if(key == GLFW_KEY_S&& action != GLFW_RELEASE){
            Window.camz -= 0.01;
        }
        if(key == GLFW_KEY_A && action != GLFW_RELEASE){
            Window.camx -= 0.01;
        }
        if(key == GLFW_KEY_D && action != GLFW_RELEASE){
            Window.camx += 0.01;
        }
        if(key == GLFW_KEY_SPACE && action != GLFW_RELEASE){
            Window.camy -= 0.01;
        }
        if(key == GLFW_KEY_LEFT_SHIFT && action != GLFW_RELEASE){
            Window.camy += 0.01;
        }
    }
    
}
