using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;
using Random = UnityEngine.Random;
using RandomMathematics = Unity.Mathematics.Random;

[ExecuteInEditMode]
public class SimpleFractal : MonoBehaviour
{
    [HideInInspector][SerializeField]private Texture2D texture = null;
    private RandomMathematics random;
    void Start()
    {
        //初始化纹理大小
        int width = Mathf.ClosestPowerOfTwo(Camera.main.pixelWidth);
        int height = Mathf.ClosestPowerOfTwo(Camera.main.pixelHeight);
        //初始化随机数
        Random.InitState((width - Camera.main.pixelWidth) * (height - Camera.main.pixelHeight));
        random = new RandomMathematics((uint)((width - Camera.main.pixelWidth) * (height - Camera.main.pixelHeight)));
        //构建并设置纹理
        texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
        GetComponent<Renderer>().sharedMaterial.mainTexture = texture;
    }

    void Update()
    {
        if (texture)
        {
            var colorArray = texture.GetPixelData<Color32>(0);
            var generatedColorJob = new GeneratedColorJob_SimpleFractal();
            generatedColorJob.colorArray = colorArray;
            generatedColorJob.time = Time.time;
            generatedColorJob.w = texture.width;
            generatedColorJob.h = texture.height;
            JobHandle scheduleJobDependency = new JobHandle();
            JobHandle generatedColorJobHandle = generatedColorJob.ScheduleParallel(colorArray.Length, 16, scheduleJobDependency);
            generatedColorJobHandle.Complete();
            texture.SetPixelData(colorArray, 0);
            texture.Apply();
        }
    }
}

[BurstCompile]
public struct GeneratedColorJob_SimpleFractal : IJobFor
{
    public float time;
    public int w, h;
    public NativeArray<Color32> colorArray;
    public void Execute(int index)
    {
        int i = index % w;
        int j = index / w;
        Color32 color = PixelColor(i, j);
        colorArray[index] = color;
    }

    private Color32 PixelColor(int i,int j)
    {
        Color32 c32 = new Color32();
        //---------编写你的逻辑, 不要超过2023个字节（包括空格）
        i += (int)(time * 0.1f * w);
        j += (int)(time * 0.1f * h);
        c32.r = (byte)(j^j-i^i);
        c32.g = (byte)(i^2+j^2);
        c32.b = (byte)(i^i-j^j);
        //---------
        return c32;
    }
}
