package raymarcher.window;

import org.joml.Vector3f;
import org.lwjgl.BufferUtils;
import org.joml.Vector2f;

import static org.lwjgl.opengl.GL45.*;

import java.nio.FloatBuffer;
import java.nio.IntBuffer;

public class Display {
	
	private float[] vertexArray;
	private int[] indices;
	
	private int vboID, iboID;
	
	public Display() {
		vertexArray = new float[] {
				-1, -1, 0, 0.0f, 0.0f,
				-1, 1, 0,  0.0f, 1.0f,
				1, -1, 0,  1.0f, 0.0f,

				1, 1, 0,  	1.0f, 1.0f,
		};
		
		indices = new int[] {
				0, 1, 2,
				2, 3, 1
		};
	}
	
	public void create() {
		vboID = glGenBuffers();
		glBindBuffer(GL_ARRAY_BUFFER, vboID);
		
		FloatBuffer vertexBuffer = BufferUtils.createFloatBuffer(vertexArray.length);
		vertexBuffer.put(vertexArray).flip();
		glBufferData(GL_ARRAY_BUFFER, vertexBuffer, GL_STATIC_DRAW);
		
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		
		iboID = glGenBuffers();
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iboID);
		
		IntBuffer indexBuffer = BufferUtils.createIntBuffer(indices.length);
		indexBuffer.put(indices).flip();
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer, GL_STATIC_DRAW);
		
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
	
	public void delete() {
		glDeleteBuffers(vboID);
		glDeleteBuffers(iboID);
	}
	
	public void setPointers() {
		glVertexAttribPointer(0, 3, GL_FLOAT, false, 5 * Float.BYTES, 0);
		glVertexAttribPointer(1, 2, GL_FLOAT, false, 5*Float.BYTES, 3*Float.BYTES);
	}
	
	public int getVboID() {
		return vboID;
	}

	public int getIboID() {
		return iboID;
	}
	
	public int getVertexCount() {
		return vertexArray.length / 3;
	}
	
	public int getIndexCount() {
		return indices.length;
	}

}
