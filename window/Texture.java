package window;

import org.joml.Vector3f;
import org.lwjgl.BufferUtils;
import org.joml.Vector2f;

import static org.lwjgl.opengl.GL40.*;

import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

public class Texture{

    private int id;

    public Texture(int id){
        this.id = id;
    }

    public int getId(){
        return id;
    }

	
    public Texture loadTexture(){

        //create a byte buffer big enough to store RGBA values
        ByteBuffer buffer = ByteBuffer.allocateDirect(4 * 800 * 4*600);
    
        //flip the buffer so its ready to read
        buffer.flip();
    
        //create a texture
        int id = glGenTextures();
    
        //bind the texture
        glBindTexture(GL_TEXTURE_2D, id);
    
        //tell opengl how to unpack bytes
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
        //set the texture parameters, can be GL_LINEAR or GL_NEAREST
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
        //upload texture
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 800, 600, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
        // Generate Mip Map
        glGenerateMipmap(GL_TEXTURE_2D);
    
        return new Texture(id); 
    }

}