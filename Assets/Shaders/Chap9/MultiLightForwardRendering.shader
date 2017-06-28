// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "KT/MultiLightForwardRendering"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("bump scale", Float) = 1.0
		_Specular ("Specular Color", Color) = (1,1,1,1)
		_Tint ("Tint", Color) = (1,1,1,1)
		_Gloss ("Gloss", Range(0.8, 256)) = 20
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Specular;
			fixed4 _Tint;
			float _Gloss;
			float _BumpScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent: TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 worldNormal : TEXCOORD2;
				float3 worldTangent : TEXCOORD3;
				float3 worldBinormal : TEXCOORD4;
				float4 worldPos : TEXCOORD5;
				SHADOW_COORDS(6)

				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBinormal = normalize(i.worldBinormal);

				fixed3 bump = normalize(UnpackNormal(tex2D(_BumpMap, i.uv.zw)));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy))); //make sure z is always greater than or equal 0
				bump = normalize(bump);

				//tangent to world transform
				fixed3 wBump = bump.x * i.worldTangent + bump.y * i.worldBinormal + bump.z * i.worldNormal;
				
				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

				//ambient term(only calculated in base pass)
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 wLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 wViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//diffuse term
				fixed3 diffuse = _LightColor0.rgb * (dot(wLightDir, wBump) * 0.5 + 0.5);
				
				//specular term
				fixed3 halfVec = normalize(wViewDir + wLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(halfVec, wBump) * 0.5 + 0.5, _Gloss);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);

				fixed3 col = albedo * (ambient + diffuse * atten ) + specular * atten;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col, 1);
			}
			ENDCG
		}

		
		Pass
		{
			//for other pixel lights
			Tags{ "LightMode" = "ForwardAdd" }

			Blend One One

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdadd
			// make fog work
			#pragma multi_compile_fog
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityCG.cginc"

			fixed4 _Specular;
			fixed4 _Tint;
			float _Gloss;
			float _BumpScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent: TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 worldNormal : TEXCOORD2;
				float3 worldTangent : TEXCOORD3;
				float3 worldBinormal : TEXCOORD4;
				float4 worldPos : TEXCOORD5;
				SHADOW_COORDS(6)
				
				float4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBinormal = normalize(i.worldBinormal);

				fixed3 bump = normalize(UnpackNormal(tex2D(_BumpMap, i.uv.zw)));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy))); //make sure z is always greater than or equal 0
				bump = normalize(bump);

				//tangent to world transform
				fixed3 wBump = normalize(bump.x * i.worldTangent + bump.y * i.worldBinormal + bump.z * i.worldNormal);

				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

				fixed3 wLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 wViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//diffuse term
				fixed3 diffuse = _LightColor0.rgb * (dot(wLightDir, wBump) * 0.5 + 0.5);
				
				//specular term
				fixed3 halfVec = normalize(wViewDir + wLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(halfVec, wBump) * 0.5 + 0.5, _Gloss);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);

				fixed3 col = (albedo * diffuse + specular) * atten;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return fixed4(col, 1);
			}
			ENDCG
		}

	}

	FallBack "Bumped Specular" //make sure there is a fallback. This fallback may contain shadow effect. 
}
