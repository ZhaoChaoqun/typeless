import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Sequence,
  Img,
  staticFile,
} from "remotion";

// 颜色配置 - iPhone 发布会风格
const colors = {
  background: "#000000",
  text: "#ffffff",
  textMuted: "rgba(255, 255, 255, 0.6)",
  accent: "#0071e3", // Apple Blue
  gradientStart: "#1a1a1a",
  gradientEnd: "#000000",
};

// 浮动 Emoji 背景
const FloatingEmojis: React.FC<{ opacity?: number }> = ({ opacity = 0.15 }) => {
  const frame = useCurrentFrame();
  const emojis = ["🎤", "💬", "⚡", "🔒", "🌐", "✨", "🎯", "💡", "🚀", "⌨️"];

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        opacity,
      }}
    >
      {emojis.map((emoji, i) => {
        const x = (i * 192 + frame * (0.3 + i * 0.1)) % 2100 - 100;
        const y = (i * 108 + Math.sin(frame * 0.02 + i) * 50) % 1200;
        const scale = 0.8 + Math.sin(frame * 0.03 + i * 2) * 0.2;
        const rotation = Math.sin(frame * 0.01 + i) * 15;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              fontSize: 60 + i * 5,
              transform: `scale(${scale}) rotate(${rotation}deg)`,
              filter: "blur(1px)",
            }}
          >
            {emoji}
          </div>
        );
      })}
    </div>
  );
};

// HUD 组件 - 模拟实际的 OverlayView
const HUD: React.FC<{ state: "recording" | "processing"; frame: number }> = ({
  state,
  frame,
}) => {
  const dots = 5;

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 4,
        padding: "12px 20px",
        background: "rgba(0, 0, 0, 0.85)",
        borderRadius: 22,
        boxShadow: "0 4px 20px rgba(0, 0, 0, 0.5)",
      }}
    >
      {state === "recording" ? (
        // 录音动画 - 5个跳动的白点
        [...Array(dots)].map((_, i) => {
          const phase = frame * 0.3 + i * 0.5;
          const offset = Math.sin(phase) * 6;
          return (
            <div
              key={i}
              style={{
                width: 8,
                height: 8,
                borderRadius: "50%",
                background: "#ffffff",
                transform: `translateY(${offset}px)`,
              }}
            />
          );
        })
      ) : (
        // 处理中指示器
        <div
          style={{
            width: 20,
            height: 20,
            border: "2px solid rgba(255,255,255,0.3)",
            borderTopColor: "#fff",
            borderRadius: "50%",
            transform: `rotate(${frame * 10}deg)`,
          }}
        />
      )}
    </div>
  );
};

// 模拟编辑器/输入区域
const InputArea: React.FC<{
  text: string;
  showCursor?: boolean;
}> = ({ text, showCursor = true }) => {
  const frame = useCurrentFrame();
  const cursorVisible = showCursor && Math.floor(frame / 15) % 2 === 0;

  return (
    <div
      style={{
        background: "rgba(255, 255, 255, 0.05)",
        borderRadius: 16,
        padding: "32px 40px",
        minWidth: 600,
        minHeight: 100,
        border: "1px solid rgba(255, 255, 255, 0.1)",
        backdropFilter: "blur(20px)",
      }}
    >
      <p
        style={{
          fontSize: 32,
          fontWeight: 400,
          color: colors.text,
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif",
          lineHeight: 1.5,
          margin: 0,
        }}
      >
        {text}
        {cursorVisible && (
          <span
            style={{
              display: "inline-block",
              width: 3,
              height: 36,
              background: colors.accent,
              marginLeft: 2,
              verticalAlign: "middle",
            }}
          />
        )}
      </p>
    </div>
  );
};

// 场景1：开场 - Logo + nano typeless + Press. Speak.
const Scene1_Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const logoScale = spring({
    frame,
    fps,
    config: { damping: 12 },
  });

  const logoOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });

  const titleOpacity = interpolate(frame, [25, 45], [0, 1], {
    extrapolateRight: "clamp",
  });

  const titleY = interpolate(frame, [25, 45], [30, 0], {
    extrapolateRight: "clamp",
  });

  const subtitleOpacity = interpolate(frame, [50, 70], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: colors.background,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FloatingEmojis opacity={0.08} />

      {/* App Icon */}
      <div
        style={{
          transform: `scale(${logoScale})`,
          opacity: logoOpacity,
          marginBottom: 32,
          width: 120,
          height: 120,
          borderRadius: 28,
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 20px 60px rgba(102, 126, 234, 0.4)",
        }}
      >
        <span style={{ fontSize: 60 }}>🎙️</span>
      </div>

      {/* Title */}
      <h1
        style={{
          fontSize: 96,
          fontWeight: 700,
          color: colors.text,
          opacity: titleOpacity,
          transform: `translateY(${titleY}px)`,
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif",
          letterSpacing: "-2px",
          margin: 0,
        }}
      >
        nano typeless
      </h1>

      {/* Subtitle */}
      <p
        style={{
          fontSize: 36,
          fontWeight: 500,
          color: colors.textMuted,
          opacity: subtitleOpacity,
          marginTop: 20,
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif",
          letterSpacing: "8px",
        }}
      >
        PRESS. SPEAK.
      </p>
    </AbsoluteFill>
  );
};

// 场景2：展示 HUD 录音
const Scene2_Recording: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const hudOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const hudScale = spring({
    frame,
    fps,
    config: { damping: 15 },
  });

  const fnKeyOpacity = interpolate(frame, [20, 35], [0, 1], {
    extrapolateRight: "clamp",
  });

  const fnKeyPressed = frame > 40;

  return (
    <AbsoluteFill
      style={{
        background: colors.background,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FloatingEmojis opacity={0.06} />

      {/* HUD */}
      <div
        style={{
          position: "absolute",
          top: 200,
          opacity: hudOpacity,
          transform: `scale(${hudScale})`,
        }}
      >
        <HUD state="recording" frame={frame} />
      </div>

      {/* Fn 键提示 */}
      <div
        style={{
          position: "absolute",
          bottom: 250,
          display: "flex",
          alignItems: "center",
          gap: 20,
          opacity: fnKeyOpacity,
        }}
      >
        <div
          style={{
            width: 80,
            height: 80,
            borderRadius: 16,
            background: fnKeyPressed
              ? "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
              : "rgba(255, 255, 255, 0.1)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 28,
            fontWeight: 600,
            color: "#fff",
            boxShadow: fnKeyPressed
              ? "0 0 40px rgba(102, 126, 234, 0.6)"
              : "none",
            border: fnKeyPressed ? "none" : "1px solid rgba(255,255,255,0.2)",
            transition: "all 0.3s",
          }}
        >
          Fn
        </div>
        <span
          style={{
            fontSize: 24,
            color: colors.textMuted,
            fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
          }}
        >
          {fnKeyPressed ? "正在聆听..." : "长按开始"}
        </span>
      </div>

      {/* 声波可视化 */}
      {fnKeyPressed && (
        <div
          style={{
            position: "absolute",
            bottom: 400,
            display: "flex",
            alignItems: "center",
            gap: 6,
          }}
        >
          {[...Array(20)].map((_, i) => {
            const height = interpolate(
              Math.sin((frame + i * 8) * 0.25),
              [-1, 1],
              [15, 60]
            );
            const opacity = interpolate(
              Math.abs(i - 10),
              [0, 10],
              [1, 0.3]
            );
            return (
              <div
                key={i}
                style={{
                  width: 4,
                  height,
                  background: `rgba(102, 126, 234, ${opacity})`,
                  borderRadius: 2,
                }}
              />
            );
          })}
        </div>
      )}
    </AbsoluteFill>
  );
};

// 场景3：文字快速输出
const Scene3_FastOutput: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fullText = "语音转文字，快如闪电";

  // 更快的打字速度 - 30帧内完成
  const typedLength = Math.floor(
    interpolate(frame, [10, 40], [0, fullText.length], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    })
  );
  const displayText = fullText.slice(0, typedLength);

  const inputOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  const speedBadgeOpacity = interpolate(frame, [50, 65], [0, 1], {
    extrapolateRight: "clamp",
  });

  const speedBadgeScale = spring({
    frame: frame - 50,
    fps,
    config: { damping: 10 },
  });

  // HUD 从录音切换到处理
  const hudState = frame < 35 ? "recording" : "processing";
  const hudOpacity = interpolate(frame, [60, 75], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: colors.background,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FloatingEmojis opacity={0.06} />

      {/* HUD */}
      <div
        style={{
          position: "absolute",
          top: 150,
          opacity: hudOpacity,
        }}
      >
        <HUD state={hudState} frame={frame} />
      </div>

      {/* 输入区域 */}
      <div style={{ opacity: inputOpacity }}>
        <InputArea text={displayText} showCursor={frame < 70} />
      </div>

      {/* 速度徽章 */}
      <div
        style={{
          position: "absolute",
          bottom: 200,
          opacity: speedBadgeOpacity,
          transform: `scale(${Math.max(0, speedBadgeScale)})`,
          display: "flex",
          alignItems: "center",
          gap: 12,
        }}
      >
        <span style={{ fontSize: 48 }}>⚡</span>
        <span
          style={{
            fontSize: 28,
            fontWeight: 600,
            color: colors.text,
            fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
          }}
        >
          本地处理，极速响应
        </span>
      </div>
    </AbsoluteFill>
  );
};

// 场景4：特性展示
const Scene4_Features: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const features = [
    { icon: "🔒", title: "100% 本地", desc: "隐私安全" },
    { icon: "⚡", title: "极速识别", desc: "毫秒响应" },
    { icon: "🌐", title: "中英混合", desc: "智能切换" },
  ];

  return (
    <AbsoluteFill
      style={{
        background: colors.background,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FloatingEmojis opacity={0.05} />

      <div style={{ display: "flex", gap: 80 }}>
        {features.map((feature, index) => {
          const delay = index * 12;
          const opacity = interpolate(frame - delay, [0, 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });
          const y = interpolate(frame - delay, [0, 20], [40, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });

          return (
            <div
              key={index}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                opacity,
                transform: `translateY(${y}px)`,
              }}
            >
              <div
                style={{
                  width: 120,
                  height: 120,
                  borderRadius: 30,
                  background: "rgba(255, 255, 255, 0.05)",
                  border: "1px solid rgba(255, 255, 255, 0.1)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 56,
                  marginBottom: 24,
                }}
              >
                {feature.icon}
              </div>
              <h3
                style={{
                  fontSize: 28,
                  fontWeight: 600,
                  color: colors.text,
                  margin: 0,
                  marginBottom: 8,
                  fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
                }}
              >
                {feature.title}
              </h3>
              <p
                style={{
                  fontSize: 18,
                  color: colors.textMuted,
                  margin: 0,
                  fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
                }}
              >
                {feature.desc}
              </p>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// 场景5：结尾 CTA
const Scene5_CTA: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });

  const titleScale = spring({
    frame,
    fps,
    config: { damping: 12 },
  });

  const commandOpacity = interpolate(frame, [30, 50], [0, 1], {
    extrapolateRight: "clamp",
  });

  const commandY = interpolate(frame, [30, 50], [20, 0], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: colors.background,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <FloatingEmojis opacity={0.08} />

      {/* Logo 小版 */}
      <div
        style={{
          width: 80,
          height: 80,
          borderRadius: 20,
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: 30,
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
        }}
      >
        <span style={{ fontSize: 40 }}>🎙️</span>
      </div>

      <h1
        style={{
          fontSize: 72,
          fontWeight: 700,
          color: colors.text,
          opacity: titleOpacity,
          transform: `scale(${titleScale})`,
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif",
          letterSpacing: "-1px",
          margin: 0,
          marginBottom: 50,
        }}
      >
        nano typeless
      </h1>

      {/* 安装命令 */}
      <div
        style={{
          opacity: commandOpacity,
          transform: `translateY(${commandY}px)`,
          background: "rgba(255, 255, 255, 0.05)",
          borderRadius: 12,
          padding: "16px 32px",
          border: "1px solid rgba(255, 255, 255, 0.1)",
        }}
      >
        <code
          style={{
            fontSize: 22,
            color: "#10b981",
            fontFamily: "SF Mono, Menlo, monospace",
          }}
        >
          brew install nano-typeless
        </code>
      </div>

      {/* GitHub */}
      <p
        style={{
          fontSize: 18,
          color: colors.textMuted,
          marginTop: 40,
          opacity: commandOpacity,
          fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
        }}
      >
        github.com/ZhaoChaoqun/typeless
      </p>
    </AbsoluteFill>
  );
};

// 主视频组件
export const TypelessPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: colors.background }}>
      {/* 场景1：开场 0-90帧 (3秒) */}
      <Sequence from={0} durationInFrames={90}>
        <Scene1_Intro />
      </Sequence>

      {/* 场景2：录音演示 90-180帧 (3秒) */}
      <Sequence from={90} durationInFrames={90}>
        <Scene2_Recording />
      </Sequence>

      {/* 场景3：快速输出 180-270帧 (3秒) */}
      <Sequence from={180} durationInFrames={90}>
        <Scene3_FastOutput />
      </Sequence>

      {/* 场景4：特性展示 270-390帧 (4秒) */}
      <Sequence from={270} durationInFrames={120}>
        <Scene4_Features />
      </Sequence>

      {/* 场景5：结尾 CTA 390-540帧 (5秒) */}
      <Sequence from={390} durationInFrames={150}>
        <Scene5_CTA />
      </Sequence>
    </AbsoluteFill>
  );
};
