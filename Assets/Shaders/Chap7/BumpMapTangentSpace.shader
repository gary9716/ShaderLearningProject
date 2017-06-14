Shader "KT/BumpMapTangentSpace"
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
				float3 lightDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;

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

				/* it cannot handle non-uniform scaling
				//compute binormal from tangent and normal vectors
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				
				//construct a matrix that can transform vectors from object space to tangent space.
				float3x3 TSpaceTrans = float3x3(v.tangent.xyz, binormal, v.normal);

				//or use the macro TANGENT_SPACE_ROTATION;(defined in UnityCG.cginc)

				//transform light and view directions from object space to tangent space
				o.lightDir = mul(TSpaceTrans, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(TSpaceTrans, ObjSpaceViewDir(v.vertex)).xyz;
				*/
				
				fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				fixed3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
				fixed3 worldBinormal = normalize(cross(worldNormal, worldTangent) * v.tangent.w);

				// The matrix that transforms from world space to tangent space is inverse of tangentToWorld(also the transpose of tangentToWorld as long as it's an orthogonal matrix)
				float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);

				// Transform the light and view dir from world space to tangent space
				o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
				o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 tLightDir = normalize(i.lightDir); //lightDir in tangent space
				fixed3 tViewDir = normalize(i.viewDir); //viewDir in tangent space

				fixed3 tNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw)); //UnpackNormal would remap value from [0, 1] to [-1, 1]
				tNormal.xy *= _BumpScale;
				tNormal.z = sqrt(1 - saturate(dot(tNormal.xy, tNormal.xy))); //make sure z is always greater than or equal 0
				tNormal = normalize(tNormal);

				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

				//get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//Compute diffuse term(half-lambert)
				fixed3 diffuse = _LightColor0.rgb * (dot(tNormal, tLightDir) * 0.5 + 0.5);

				//Compute specular term(Blinn-Phong)
				fixed3 halfVec = normalize(tViewDir + tLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(tNormal, halfVec) * 0.5 + 0.5 , _Gloss);

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
