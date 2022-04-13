package raymarcher.window;

import org.lwjgl.BufferUtils;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

import static org.lwjgl.opengl.GL45.*;
import static org.lwjgl.stb.STBImage.stbi_image_free;
import static org.lwjgl.stb.STBImage.stbi_loadf;
import static org.lwjgl.stb.STBImage.stbi_set_flip_vertically_on_load;

public class Texture {
    // private String filepath;
   public int texID;

    public Texture() {
        texID = glGenTextures();
        glBindTexture(GL_TEXTURE_2D, texID);
        glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA32F, 1600, 1000);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    public Texture(String filepath) {
        // this.filepath = filepath;
        // Generate texture on GPU
        texID = glGenTextures();
        glBindTexture(GL_TEXTURE_2D, texID);

        // Set texture parameters
        // Repeat image in both directions
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        // When stretching the image
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        // When shrinking an image
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        IntBuffer width = BufferUtils.createIntBuffer(1);
        IntBuffer height = BufferUtils.createIntBuffer(1);
        IntBuffer channels = BufferUtils.createIntBuffer(1);
        stbi_set_flip_vertically_on_load(true);
        FloatBuffer image = stbi_loadf(filepath, width, height, channels, 0);
        glTextureStorage2D(texID, 1, GL_RGBA, 1600, 1200);
        // glBindImageTexture(1, texID, 0, false, 0, GL_WRITE_ONLY, GL_RGBA);
        if (image != null) {
            if (channels.get(0) == 4) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width.get(0), height.get(0),
                        0, GL_RGBA, GL_FLOAT, image);
            } else if (channels.get(0) == 3) {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width.get(0), height.get(0),
                        0, GL_RGB, GL_FLOAT, image);
            } else {
                assert false : "Error: (Texture) Unknown number of channesl '" + channels.get(0) + "'";
            }
        } else {
            assert false : "Error: (Texture) Could not load image '" + filepath + "'";
        }
        
        glGenerateMipmap(GL_TEXTURE_2D);

        stbi_image_free(image);
        unbind();
    }

    public void bind() {
        glBindTexture(GL_TEXTURE_2D, texID);
    }

    public void unbind() {
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    public void delete(){
        glDeleteTextures(GL_TEXTURE_2D);
    }
}