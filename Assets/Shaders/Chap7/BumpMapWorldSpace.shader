Shader "KT/BumpMapWorldSpace"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Tint("Tint", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

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

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				
				float3 normal : NORMAL;
				float4 tangent : TANGENT; //notice that tangent is a float4 variable, we would need w component to decide the direction of binormal(bitangent)
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1) //using TEXCOORD1
				float3 worldTangent : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldBinormal : TEXCOORD4;
				float4 worldPos : TEXCOORD5;

				float4 vertex : SV_POSITION;

			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			half _BumpScale;

			fixed4 _Specular;
			fixed4 _Tint;
			float _Gloss;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex); //same with mul(UNITY_MATRIX_MVP, v.vertex);

				//use xy to save tiling and offset information of MainTex and zw for BumpMap.
				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;				
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 wLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //lightDir in world space
				fixed3 wViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //viewDir in world space

				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent = normalize(i.worldTangent);
				i.worldBinormal = normalize(i.worldBinormal);

				fixed3 tNormal = normalize(UnpackNormal(tex2D(_BumpMap, i.uv.zw))); //UnpackNormal would remap value from [0, 1] to [-1, 1]
				tNormal.xy *= _BumpScale;
				tNormal.z = sqrt(1 - saturate(dot(tNormal.xy, tNormal.xy))); //make sure z is always greater than or equal 0
				tNormal = normalize(tNormal);

				fixed3 wNormal = normalize(tNormal.x * i.worldTangent + tNormal.y * i.worldBinormal + tNormal.z * i.worldNormal);

				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

				//get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//Compute diffuse term(half-lambert)
				fixed3 diffuse = _LightColor0.rgb * (dot(wNormal, wLightDir) * 0.5 + 0.5);

				//Compute specular term(Blinn-Phong)
				fixed3 halfVec = normalize(wViewDir + wLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(wNormal, halfVec) * 0.5 + 0.5, _Gloss);

				fixed3 color = (ambient + diffuse) * albedo + specular;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, color);

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}

	FallBack "Specular"
}
