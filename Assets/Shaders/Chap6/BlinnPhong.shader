Shader "KT/BlinnPhong"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		//_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Tint ("Tint", Color) = (1,1,1,1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
		
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
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float3 worldNormal : TEXCOORD0;
				float2 uv : TEXCOORD2;
				float4 worldPos : TEXCOORD3;

				UNITY_FOG_COORDS(1) //using TEXCOORD1
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			fixed4 _Tint;
			float _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex); //same with mul(UNITY_MATRIX_MVP, v.vertex);

				//o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject); //do transformation ourselves
				o.worldNormal = UnityObjectToWorldNormal(v.normal); //using helper function
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex); //take tiling and offset into consideration
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

				//get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldNormal = normalize(i.worldNormal);
				
				//Compute diffuse term(half-lambert)
				fixed3 diffuse = _LightColor0.rgb * (dot(worldNormal, worldLight) * 0.5 + 0.5);

				//Compute specular term(Blinn-Phong)
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfVec = normalize(viewDir + worldLight);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(worldNormal, halfVec) * 0.5 + 0.5, _Gloss);

				fixed3 color = (ambient + diffuse) * albedo + specular;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, color);

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}
}
