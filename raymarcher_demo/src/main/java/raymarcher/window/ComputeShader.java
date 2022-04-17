package raymarcher.window;

import static org.lwjgl.opengl.GL45.*;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.IntBuffer;

import org.lwjgl.BufferUtils;

import java.io.File;

public class ComputeShader {
	
	private String computeFile = new File("./raymarcher_demo/resources/raymarch_v3.cs.glsl").getAbsolutePath();
	
	public int programID, computeID;


	public ComputeShader() {}
	
	public ComputeShader(String computeFile) {
		this.computeFile = computeFile;
	}
	private static String readFile(String file){
		StringBuilder shaderSource = new StringBuilder();
		try{
		 BufferedReader reader = new BufferedReader(new FileReader(file));
		 String line;
		 while((line = reader.readLine())!=null){
		  shaderSource.append(line).append("//\n");
		 }
		 reader.close();
		}catch(IOException e){
		 e.printStackTrace();
		 System.exit(-1);
		}

		return shaderSource.toString();
	}
	
	private int loadShader(int type, String file) {
		int id = glCreateShader(type);
		glShaderSource(id, readFile(file));
		glCompileShader(id);
		
		if (glGetShaderi(id, GL_COMPILE_STATUS) == GL_FALSE) {
			System.out.println("Could Not Compile " + file);
			System.out.println(glGetShaderInfoLog(id));
		}
		
		return id;
	}
	
	public void create() {
		
		computeID = loadShader(GL_COMPUTE_SHADER, computeFile);
        glCompileShader(computeID);

        programID = glCreateProgram();
		
		glAttachShader(programID, computeID);
		glLinkProgram(programID);
		// glValidateProgram(programID);
		// glDeleteShader(computeID);

	}
	public void init(){
		glUseProgram(programID);
		
		IntBuffer params = BufferUtils.createIntBuffer(1);
        // int loc = glGetUniformLocation(programID, "ftex");
        //glGetUniformiv(programID, loc, params);//used for debugging
        Window.framebufferImageBinding = params.get(0);
		glUseProgram(0);
	}

	public void use() {
		glUseProgram(programID);
	}
	public void disp() {
		glDispatchCompute((int)Math.ceil(1600/8), (int)Math.ceil(1200/4), 1);
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
	}
	
	public void stop() {
		glUseProgram(0);
	}
	
	public void delete() {
		stop();
		glDetachShader(programID, computeID);
		glDeleteProgram(programID);
	}

}

