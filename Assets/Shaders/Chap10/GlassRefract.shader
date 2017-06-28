Shader "KT/GlassRefract"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_RefractAmount ("Refract Amount", Range(0, 1)) = 1
		_Cube ("Cube map", CUBE) = "" {}
		_Distortion ("Distortion", Range(0, 100)) = 10
		_Tint("Tint", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { 
			"RenderType"="Opaque" 
			"Queue"="Transparent"
		}
		LOD 100

		GrabPass { "_RefractTex" }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 worldTangent : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldBinormal : TEXCOORD4;
				float4 worldPos : TEXCOORD5;
				float4 scrPos : TEXCOORD6;

				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			sampler2D _RefractTex;
			float4 _RefractTex_TexelSize;

			samplerCUBE _Cube;

			fixed _RefractAmount;
			fixed _Distortion;
			fixed4 _Tint;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeGrabScreenPos(o.pos);

				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;				
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				
				UNITY_TRANSFER_FOG(o,o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
				
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //viewDir in world space

				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBinormal = normalize(i.worldBinormal);
				
				fixed3 bump = normalize(UnpackNormal(tex2D(_BumpMap, i.uv.zw))); //UnpackNormal would remap value from [0, 1] to [-1, 1]
				
				float2 offset = bump.xy * _Distortion * _RefractTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refraction = tex2D(_RefractTex, i.scrPos.xy / i.scrPos.w).rgb;
				
				fixed3 wBump = normalize(bump.x * i.worldTangent + bump.y * i.worldBinormal + bump.z * i.worldNormal);
				
				fixed3 worldReflect = reflect(-worldViewDir, wBump);
				fixed3 reflection = texCUBE(_Cube, worldReflect).rgb * albedo;

				fixed3 col = reflection * (1 - _RefractAmount) + refraction * _RefractAmount;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col,1);
			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
