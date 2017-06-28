Shader "KT/Reflect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_ReflectColor ("Reflect Color", Color) = (1 , 1 , 1 , 1)
		_ReflectAmount ("Reflect Amount", Range(0, 1)) = 1
		_Cube ("Cube map", CUBE) = "" {}
		_FresnelScale ("Fresnel scale", Range(0, 1)) = 1
		_Tint("Tint", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { 
			"RenderType"="Opaque" 
			"Queue"="Geometry"
		}
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

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
				SHADOW_COORDS(6)

				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			half _BumpScale;

			samplerCUBE _Cube;

			fixed _ReflectAmount;
			fixed4 _ReflectColor;
			fixed4 _Tint;
			fixed _FresnelScale;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;				
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				UNITY_TRANSFER_FOG(o,o.vertex);
				TRANSFER_SHADOW(o);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 wLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //lightDir in world space
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //viewDir in world space

				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBinormal = normalize(i.worldBinormal);
				

				fixed3 bump = normalize(UnpackNormal(tex2D(_BumpMap, i.uv.zw))); //UnpackNormal would remap value from [0, 1] to [-1, 1]
				bump.xy *= _BumpScale;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy))); //make sure z is always greater than or equal 0
				bump = normalize(bump);

				fixed3 wBump = normalize(bump.x * i.worldTangent + bump.y * i.worldBinormal + bump.z * i.worldNormal);
				
				fixed3 worldReflect = reflect(-worldViewDir, wBump);

				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

				//get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				//Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * (dot(wBump, wLightDir) * 0.5 + 0.5) * albedo;

				fixed3 reflection = texCUBE(_Cube, worldReflect).rgb;

				fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, wBump), 5);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);

				fixed3 col = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;
				
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col,1);
			}
			ENDCG
		}
	}

	Fallback "Reflective/Bumped VertexLit"
}
