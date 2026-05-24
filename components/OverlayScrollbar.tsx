"use client";

import { useEffect, useState } from "react";

interface OverlayScrollbarProps {
  targetRef: React.RefObject<HTMLElement | null>;
  contentKey?: string;
}

export function OverlayScrollbar({ targetRef, contentKey }: OverlayScrollbarProps) {
  const [visible, setVisible] = useState(false);
  const [thumb, setThumb] = useState({ height: 48, top: 0 });
  const [showTrack, setShowTrack] = useState(false);

  useEffect(() => {
    const el = targetRef.current;
    if (!el) return;

    let hideTimer: ReturnType<typeof setTimeout>;

    const updateThumb = () => {
      const { scrollTop, scrollHeight, clientHeight } = el;
      const canScroll = scrollHeight > clientHeight + 1;
      setShowTrack(canScroll);

      if (!canScroll) return;

      const ratio = clientHeight / scrollHeight;
      const height = Math.max(clientHeight * ratio, 36);
      const maxTop = clientHeight - height;
      const top =
        scrollHeight === clientHeight
          ? 0
          : (scrollTop / (scrollHeight - clientHeight)) * maxTop;

      setThumb({ height, top });
    };

    const onScroll = () => {
      updateThumb();
      setVisible(true);
      clearTimeout(hideTimer);
      hideTimer = setTimeout(() => setVisible(false), 900);
    };

    updateThumb();
    el.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", updateThumb);

    const observer = new ResizeObserver(updateThumb);
    observer.observe(el);

    return () => {
      el.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", updateThumb);
      observer.disconnect();
      clearTimeout(hideTimer);
    };
  }, [targetRef, contentKey]);

  if (!showTrack) return null;

  return (
    <div
      aria-hidden
      className={`pointer-events-none absolute bottom-0 right-1.5 top-0 z-10 w-1.5 transition-opacity duration-300 ${
        visible ? "opacity-100" : "opacity-0"
      }`}
    >
      <div
        className="absolute w-full rounded-full bg-purple-600/30 shadow-sm transition-[height,transform] duration-150 ease-out"
        style={{
          height: `${thumb.height}px`,
          transform: `translateY(${thumb.top}px)`,
        }}
      />
    </div>
  );
}
