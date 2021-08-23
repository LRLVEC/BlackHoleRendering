#include <GL/_Window.h>
#include <GL/_Texture.h>
#include <CUDA/_CUDA.h>
#include <_Math.h>
#include <_Time.h>
#include <RayTracing/_RayTracing.h>
#include <_STL.h>
#include <_BMP.h>
#include <random>

namespace OpenGL
{
	struct RayTrace :OpenGL
	{
		struct TextureData :Texture::Data
		{
			unsigned int size;
			float* data;


			TextureData(unsigned int _size, String<char> const& _data)
				:
				size(_size)
			{
				//_data.printInfo();
				data = (float*)malloc(size * sizeof(float));
				unsigned int n(0);
				for (unsigned int c0(0); c0 < size; ++c0)
				{
					unsigned int dn(0);
					sscanf(_data.data + n, "%f%n", data + c0, &dn);
					//printf("%.2f ", data[c0]);
					n += dn;
				}
			}
			~TextureData()
			{
				if (data)
				{
					free(data);
					data = nullptr;
				}
			}

			virtual void* pointer()override
			{
				return data;
			}
		};

		struct Renderer :Program
		{
			RayTracing::View view;
			Buffer viewBuffer;
			BufferConfig viewArray;
			VertexAttrib position;

			Renderer(SourceManager* _sm)
				:
				Program(_sm, "Renderer", Vector<VertexAttrib*>{&position}),
				view(),
				viewBuffer(&view),
				viewArray(&viewBuffer, ArrayBuffer),
				position(&viewArray, 0, VertexAttrib::two,
					VertexAttrib::Float, false, sizeof(Math::vec2<float>), 0, 0)
			{
				init();
			}
			virtual void initBufferData()override
			{
			}
			virtual void run()override
			{
				glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
				glClear(GL_COLOR_BUFFER_BIT);
				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
			}
		};

		SourceManager sm;
		bool sizeChanged;

		RayTracing::FrameScale frameScale;
		RayTracing::Transform transform;

		Buffer frameSizeBuffer;
		Buffer transBuffer;

		BufferConfig frameSizeUniform;
		BufferConfig transUniform;

		BMPCubeData cubeData;
		TextureCube cube;

		static constexpr unsigned int textureWidth = 64;
		TextureData textureDataCase1;
		TextureData textureDataCase2;
		TextureData textureDataAlphaM;
		Texture textureCase1;
		Texture textureCase2;
		Texture textureAlphaM;
		TextureConfig<TextureStorage2D>textureConfigCase1;
		TextureConfig<TextureStorage2D>textureConfigCase2;
		TextureConfig<TextureStorage1D>textureConfigCase2AlphaM;

		Renderer renderer;

		RayTrace(Math::vec2<unsigned int> const& _size)
			:
			sm(),
			sizeChanged(true),
			frameScale(),
			transform({ {60.0},{0.002,0.9,0.001},{0.02},{0,0,20},700.0 }),
			frameSizeBuffer(&frameScale),
			transBuffer(&transform.bufferData),
			frameSizeUniform(&frameSizeBuffer, UniformBuffer, 0),
			transUniform(&transBuffer, UniformBuffer, 1),
			cubeData("resources/room/"),
			cube(&cubeData, 0, RGBA32f, 1, cubeData.bmp[0].header.width, cubeData.bmp[0].header.height),
			textureDataCase1(textureWidth* textureWidth, sm.folder.find("resources/unified.txt").readText()),
			textureDataCase2(textureWidth* textureWidth, sm.folder.find("resources/case2.txt").readText()),
			textureDataAlphaM(textureWidth, sm.folder.find("resources/alpha_m.txt").readText()),
			textureCase1(&textureDataCase1, 1),
			textureCase2(&textureDataCase2, 2),
			textureAlphaM(&textureDataAlphaM, 3),
			textureConfigCase1(&textureCase1, Texture2D, R32f, 1, textureWidth, textureWidth),
			textureConfigCase2(&textureCase2, Texture2D, R32f, 1, textureWidth, textureWidth),
			textureConfigCase2AlphaM(&textureAlphaM, Texture1D, R32f, 1, textureWidth),
			renderer(&sm)
		{
			cube.dataInit(0, TextureInputBGRInt, TextureInputUByte);
			textureConfigCase1.dataInit(0, TextureInputR, TextureInputFloat);
			textureConfigCase2.dataInit(0, TextureInputR, TextureInputFloat);
			textureConfigCase2AlphaM.dataInit(0, TextureInputR, TextureInputFloat);

			renderer.use();
			cube.bindUnit();
			textureCase1.bindUnit();
			textureCase2.bindUnit();
			textureAlphaM.bindUnit();
			
			using namespace TextureParameter;
			cube.parameteri(TextureMinFilter, MinFilter_Linear);
			textureConfigCase1.parameteri(TextureMinFilter, MinFilter_Nearest);
			textureConfigCase2.parameteri(TextureMinFilter, MinFilter_Linear);
			textureConfigCase2AlphaM.parameteri(TextureMinFilter, MinFilter_Nearest);

			//textureConfigCase2.parameteri(TextureWarpS, Wrap_ClampToEdge);
			//textureConfigCase2.parameteri(TextureWarpT, Wrap_ClampToEdge);

			float black[4]{ 0 };

			//glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, black);

			glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
		}
		virtual void init(FrameScale const& _size) override
		{
			glViewport(0, 0, _size.w, _size.h);
			transform.init(_size);
			frameScale.scale = { unsigned int(_size.w),unsigned int(_size.h) };
			renderer.viewArray.dataInit();
			frameSizeUniform.dataInit();
			sizeChanged = false;
			transUniform.dataInit();
		}
		virtual void run() override
		{
			transform.bufferData.trans.times = 0;
			if (sizeChanged)
			{
				glViewport(0, 0, frameScale.scale.data[0], frameScale.scale.data[1]);
				renderer.use();
				frameSizeUniform.refreshData();
				transform.bufferData.trans.times = 0;
				sizeChanged = false;
			}
			transform.operate();
			if (transform.updated)
			{
				transUniform.refreshData();
				transform.updated = false;
			}
			renderer.use();
			renderer.run();
		}
		virtual void frameSize(int _w, int _h) override
		{
			frameScale.scale = { unsigned int(_w),unsigned int(_h) };
			transform.persp.y = _h;
			transform.persp.updated = true;
			sizeChanged = true;
		}
		virtual void framePos(int, int) override
		{
		}
		virtual void frameFocus(int) override
		{
		}
		virtual void mouseButton(int _button, int _action, int _mods) override
		{
			switch (_button)
			{
			case GLFW_MOUSE_BUTTON_LEFT:transform.mouse.refreshButton(0, _action); break;
			case GLFW_MOUSE_BUTTON_MIDDLE:transform.mouse.refreshButton(1, _action); break;
			case GLFW_MOUSE_BUTTON_RIGHT:transform.mouse.refreshButton(2, _action); break;
			}
		}
		virtual void mousePos(double _x, double _y) override
		{
			transform.mouse.refreshPos(_x, _y);
		}
		virtual void mouseScroll(double _x, double _y) override
		{
			if (_y != 0.0)
				transform.scroll.refresh(_y);
		}
		virtual void key(GLFWwindow* _window, int _key, int _scancode, int _action, int _mods) override
		{
			switch (_key)
			{
			case GLFW_KEY_ESCAPE:
				if (_action == GLFW_PRESS)
					glfwSetWindowShouldClose(_window, true);
				break;
			case GLFW_KEY_A:transform.key.refresh(0, _action); break;
			case GLFW_KEY_D:transform.key.refresh(1, _action); break;
			case GLFW_KEY_W:transform.key.refresh(2, _action); break;
			case GLFW_KEY_S:transform.key.refresh(3, _action); break;
			}
		}
	};
}

int main()
{
	OpenGL::OpenGLInit init(4, 5);
	Window::Window::Data winPara
	{
		"BlackHoleRendering",
		{
			{1200, 1200},
			true, false,
		}
	};
	Window::WindowManager wm(winPara);
	OpenGL::RayTrace test({ 1200, 1200 });
	wm.init(0, &test);
	glfwSwapInterval(1);
	FPS fps;
	fps.refresh();
	while (!wm.close())
	{
		wm.pullEvents();
		wm.render();
		wm.swapBuffers();
		fps.refresh();
		fps.printFPS(1);
	}
	return 0;
}
