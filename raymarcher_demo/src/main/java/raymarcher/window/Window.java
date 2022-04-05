package raymarcher.window;

import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL45.*;

import java.io.File;

import org.joml.Vector2f;
import org.joml.Vector3f;
import org.lwjgl.glfw.GLFWCursorPosCallback;
import org.lwjgl.opengl.GL;
import raymarcher.inputs.KeyInput;
import raymarcher.inputs.MouseInput;

public class Window {

	private static Window instance = null;

	public static int framebufferImageBinding;

	private int width = 1600;
	private int height = 1200;

	public static int tex_output;

    public static int tex_output_temp;

	private int vaoID, uniformID, uniform2ID, uniform3ID, uniform4ID/*, uniform5ID*/;
	public static float xx = 0;

	public static float camx = 0, camy = 0, camz = 0;

	public static Vector3f cam = new Vector3f();
	public static Vector2f rot = new Vector2f();

	float speed = 0.002f;

	private Model model;
	private Shader shader;
	private ComputeShader cs;
	public static int texBuff, tex_out, sampler;

	//private float[] vertexArray;

	private GLFWCursorPosCallback cursor = new MouseInput();

	KeyInput keyboard;

	private long window;

	int screenTex;

	public static Texture skybox;

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

	private void createTexture() {
        texBuff = glGenTextures();
        glBindTexture(GL_TEXTURE_2D, texBuff);
        glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA32F, width, height);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

	public void init() {
		glfwInit();

		glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
		glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

		window = glfwCreateWindow(width, height, "Window", 0, 0);
		glfwMakeContextCurrent(window);
		//glfwSwapInterval(0);
		GL.createCapabilities();

		glfwSetCursorPosCallback(window, cursor);
		glfwSetKeyCallback(window, keyboard = new KeyInput());




		cs = new ComputeShader();
		cs.create();
		cs.init();
		shader = new Shader();
		shader.create();

		createTexture();
		vaoID = glGenVertexArrays();
		skybox = new Texture( new File("./raymarcher_demo/resources/street.JPG").getAbsolutePath());

		glBindVertexArray(vaoID);

		model = new Model(new Vector3f(0, 0, 0), new Vector2f(1, 1), new Vector3f(0, 0, 0));
		model.create();


		shader.use();
		uniform2ID = glGetUniformLocation(cs.programID, "xx");
		uniformID = glGetUniformLocation(cs.programID, "mouse_xy");
		uniform3ID = glGetUniformLocation(cs.programID, "orig");
		uniform4ID = glGetUniformLocation(shader.programID, "tex");

		shader.stop();





		glfwShowWindow(window);
	}

	public void loop() {

		while (!glfwWindowShouldClose(window)) {
			glfwPollEvents();
			//glViewport(0, 0, width, height);

			xx += speed;
			if (xx > 0 || xx < -4)
				speed = -speed;

			cs.use();
			glUniform1f(uniform2ID, xx);
			glUniform2f(uniformID, dx*2, dy*2);
			glUniform3f(uniform3ID, cam.x, cam.y, cam.z);

			glActiveTexture(GL_TEXTURE0);
			glBindImageTexture(0, texBuff, 0, false, 0, GL_WRITE_ONLY, GL_RGBA32F);
			glBindTexture(GL_TEXTURE_2D, texBuff);
			glBindTextureUnit(0, texBuff);

			glActiveTexture(GL_TEXTURE0+1);
			glBindTexture(GL_TEXTURE_2D, skybox.texID);
			glBindImageTexture(1, skybox.texID, 0, false, 0, GL_READ_ONLY, GL_RGBA);
			glBindTextureUnit(1, skybox.texID);

			cs.disp();
			// glBindImageTexture(0, 0, 0, false, 0, GL_WRITE_ONLY, GL_RGBA32F);
			// glBindImageTexture(1, 0, 0, false, 0, GL_READ_ONLY, GL_RGBA32F);
			cs.stop();

			//glClear(GL_COLOR_BUFFER_BIT);
			shader.use();
			Render.render(vaoID, model);

			glUniform1i(uniform4ID, 0);

			shader.stop();
			glfwSwapBuffers(window);

		}

		glDeleteVertexArrays(vaoID);
		model.delete();
		// cs.delete();
		shader.delete();
		// tex.unbind();
		// tex.delete();

		glfwTerminate();
	}

}
