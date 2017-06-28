using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RealtimeCubemapUpdater : MonoBehaviour {

	public int cubemapSize = 64;

	public RenderTexture cubemapRenTex;
	public Camera cam;

	public bool oneFacePerFrame;

	// Use this for initialization
	void Start () {
		UpdateCubemap(63); //all six faces
	}
	
	// LateUpdate is called once per frame
	void LateUpdate () {
		if(oneFacePerFrame) {
			int faceToRender = Time.frameCount % 6;
			int mask = 1 << faceToRender;
			UpdateCubemap(mask);
		}
		else {
			UpdateCubemap(63);
		}
			
	}

	void UpdateCubemap(int faceMask) {
		if(cam == null) {
			cam = this.gameObject.AddComponent<Camera>();
		}	

		cam.farClipPlane = 100; //dont render too far into cubemap
		cam.enabled = false;

		if(cubemapRenTex == null) {
			cubemapRenTex = new RenderTexture(cubemapSize, cubemapSize, 16);
			cubemapRenTex.dimension = UnityEngine.Rendering.TextureDimension.Cube;
			cubemapRenTex.hideFlags = HideFlags.HideAndDontSave;
			GetComponent<Renderer>().sharedMaterial.SetTexture ("_Cube", cubemapRenTex);
		}

		cam.RenderToCubemap(cubemapRenTex, faceMask);

	}
}
