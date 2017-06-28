Shader "KT/MultiLightAlphaTest"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Main Tint", Color) = (1,1,1,1)
		_Gloss("Gloss", Float) = 0.01
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader
	{
		Tags { 
			"Queue" = "AlphaTest"
			"IgnoreProjector" = "True"
			"RenderType"="TransparentCutout" 
		}
		LOD 100

		Pass
		{
			Tags {
				"LightMode" = "ForwardBase"	
			}

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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 worldNormal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
				
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;
			fixed _Cutoff;
			fixed _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				
				TRANSFER_SHADOW(o);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 texCol = tex2D(_MainTex, i.uv);
				
				//alpha test
				clip(texCol.a - _Cutoff);

				//equal to
				//if ((texCol.a - _Cutoff) < 0) {
				//	discard;
				//}

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = texCol.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 diffuse = _LightColor0.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);

				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfVec = normalize(worldLightDir + worldViewDir);
				fixed3 specular = _LightColor0.rgb * pow(dot(worldNormal, halfVec) * 0.5 + 0.5, _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);

				fixed3 col = (ambient + diffuse * atten) * albedo.rgb + specular * atten;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col,1);
			}
			ENDCG
		}

		Pass
		{
			Tags {
				"LightMode" = "ForwardAdd"	
			}

			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 worldNormal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
				
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;
			fixed _Cutoff;
			fixed _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				
				TRANSFER_SHADOW(o);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 texCol = tex2D(_MainTex, i.uv);
				
				//alpha test
				clip(texCol.a - _Cutoff);

				//equal to
				//if ((texCol.a - _Cutoff) < 0) {
				//	discard;
				//}

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 albedo = texCol.rgb * _Color.rgb;
				fixed3 diffuse = _LightColor0.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);
				
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfVec = normalize(worldLightDir + worldViewDir);
				fixed3 specular = _LightColor0.rgb * pow(dot(worldNormal, halfVec) * 0.5 + 0.5, _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);

				fixed3 col = (diffuse * albedo.rgb + specular) * atten;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col,1);
			}
			ENDCG
		}
	}

	Fallback "Transparent/Cutout/VertexLit"
}
