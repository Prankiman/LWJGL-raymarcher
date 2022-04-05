package raymarcher.window;

import static org.lwjgl.opengl.GL45.*;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.File;

public class Shader {
	
	private String vertexFile = new File("./raymarcher_demo/resources/vertex.vs.glsl").getAbsolutePath();
	private String fragmentFile = new File("./raymarcher_demo/resources/fragment.fs.glsl").getAbsolutePath();
	
	public int programID, vertexID, fragmentID, computeID;


	public Shader() {}
	
	public Shader(String vertexFile, String fragmentFile) {
		this.vertexFile = vertexFile;
		this.fragmentFile = fragmentFile;
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
		programID = glCreateProgram();
		
		// computeID = loadShader(GL_COMPUTE_SHADER, computeFile);

		vertexID = loadShader(GL_VERTEX_SHADER, vertexFile);
	
		fragmentID = loadShader(GL_FRAGMENT_SHADER, fragmentFile);
		
		// glAttachShader(programID, computeID);
		// glLinkProgram(programID);
		glAttachShader(programID, vertexID);
		glAttachShader(programID, fragmentID);
		glLinkProgram(programID);
		// glBindFragDataLocation(programID, 0, "color");
		// glDeleteShader(vertexID);
        // glDeleteShader(fragmentID);
		// glValidateProgram(programID);
	}
	
	public void use() {
		glUseProgram(programID);
	}
	
	public void stop() {
		glUseProgram(0);
	}
	
	public void delete() {
		stop();
		glDetachShader(programID, vertexID);
		glDetachShader(programID, fragmentID);
		glDeleteShader(vertexID);
		glDeleteShader(fragmentID);
		glDeleteProgram(programID);
	}

}
