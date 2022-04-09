package raymarcher.inputs;

import static org.lwjgl.glfw.GLFW.*;

import org.lwjgl.glfw.GLFWKeyCallback;
import org.joml.Vector2f;
import org.joml.Vector3f;

import raymarcher.window.Window;

public class KeyInput extends GLFWKeyCallback{


    Vector3f tempx = new Vector3f(0.1f, 0, 0);
    Vector3f tempz = new Vector3f(0, 0, 0.1f);

    @Override
    public void invoke(long window, int key, int scancode, int action, int mods) {
        Window.rot = new Vector2f((((Window.dx*2)/400-1)), 2*((Window.dy*2)/300-1)).mul(0.2f);
        if(key == GLFW_KEY_W&& action != GLFW_RELEASE){
            Window.cam = Window.cam.add(rotateYP(tempz, Window.rot.x, Window.rot.y));
        }
        if(key == GLFW_KEY_S&& action != GLFW_RELEASE){
            Window.cam = Window.cam.sub(rotateYP(tempz, Window.rot.x, Window.rot.y));
        }
        if(key == GLFW_KEY_A && action != GLFW_RELEASE){
            Window.cam = Window.cam.sub(rotateYP(tempx, Window.rot.x, Window.rot.y));
        }
        if(key == GLFW_KEY_D && action != GLFW_RELEASE){
            Window.cam = Window.cam.add(rotateYP(tempx, Window.rot.x, Window.rot.y));
        }
        if(key == GLFW_KEY_SPACE && action != GLFW_RELEASE){
            Window.cam.y -= 0.1f;
        }
        if(key == GLFW_KEY_LEFT_SHIFT && action != GLFW_RELEASE){
            Window.cam.y += 0.1f;
        }

        if(key == GLFW_KEY_P && action != GLFW_RELEASE && Window.res > 1){
            Window.res -= 1f;
        }
        if(key == GLFW_KEY_O && action != GLFW_RELEASE && Window.res < 16){
            Window.res += 1f;
        }
        
    }

    Vector3f rotateYP(Vector3f v, float yaw, float pitch) {
        //needs to be in radians
        float yawRads = yaw;
        float pitchRads = pitch;
    
       Vector3f rotateY = new Vector3f(), rotateX = new Vector3f();
    

        // Rotate around the Y axis (pitch)
        rotateY.x = v.x;
        rotateY.y = (float)(v.y*Math.cos(pitchRads) + v.z*Math.sin(pitchRads));
        rotateY.z = (float)(-v.y*Math.sin(pitchRads) + v.z*Math.cos(pitchRads));
        
        //Rotate around X axis (yaw)
        rotateX.y = rotateY.y;
        rotateX.x = (float)(rotateY.x*Math.cos(yawRads) + rotateY.z*Math.sin(yawRads));
        rotateX.z = (float)(-rotateY.x*Math.sin(yawRads) + rotateY.z*Math.cos(yawRads));
    
        
        return rotateX;
    }
    
}
