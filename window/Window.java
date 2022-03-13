package window;

import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL40.*;

import java.nio.DoubleBuffer;
import java.nio.FloatBuffer;

import org.joml.Vector2f;
import org.joml.Vector3f;
import org.lwjgl.BufferUtils;
import org.lwjgl.glfw.GLFWCursorPosCallback;
import org.lwjgl.opengl.GL;
import org.lwjgl.system.windows.MOUSEINPUT;

import inputs.MouseInput;

public class Window {
	
	private static Window instance = null;
	
	private int width = 800;
	private int height = 600;
	
	private int vaoID, vboID, uniformID, uniform2ID;

	public static float xx = 0;

	float speed = 0.002f;
	
	private Model model;
	private Shader shader;
	
	private float[] vertexArray;
	
	private GLFWCursorPosCallback cursor;

	private long window;

	public static float dx, dy;
	
	private Window() {}
	
	public static Window get() {
		if (instance == null) {
			instance = new Window();
		}
		
		return instance;
	}
	
	public void run() {
		init();
		loop();
	}
	
	public void init() {
		glfwInit();
		
		glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
		glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		
		window = glfwCreateWindow(width, height, "Window", 0, 0);
		glfwMakeContextCurrent(window);
		GL.createCapabilities();
		
		glfwSetCursorPosCallback(window, cursor = new MouseInput());

		shader = new Shader();
		shader.create();

		uniform2ID = glGetUniformLocation(shader.programID, "xx");
		uniformID = glGetUniformLocation(shader.programID, "sphere_xy");

		vaoID = glGenVertexArrays();

		glBindVertexArray(vaoID);
		
		model = new Model(new Vector3f(0, 0, 0), new Vector2f(1, 1), new Vector3f(0, 0, 0));
		model.create();

		// tex = new Texture(0);
		
		glfwShowWindow(window);
	}
	
	public void loop() {
		while (!glfwWindowShouldClose(window)) {
			xx += speed;
			if (xx > 0 || xx < -4)
				speed = -speed;

			shader.use();
			glUniform1f(uniform2ID, xx);
			glUniform2f(uniformID, 2*(dx/400-1), 2*(dy/300-1));
			// System.out.println(dx);
			glClearColor(1, 1, 1, 1);
			glClear(GL_COLOR_BUFFER_BIT);
			Render.render(vaoID, model);
			glfwSwapBuffers(window);
			glfwPollEvents();
			shader.stop();
		}
		
		glDeleteVertexArrays(vaoID);
		model.delete();
		shader.delete();
		
		glfwTerminate();
	}

}
