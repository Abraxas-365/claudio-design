/**
 * ui-kit.jsx — Minimal shared UI component library for design mockups.
 *
 * Components: Button, Card, Badge, Input, Modal, Toast, Navbar, Sidebar
 *
 * Design system:
 *   - Colors: oklch() with CSS custom properties
 *   - Typography: Source Serif 4 (display), Inter (body)
 *   - Spacing: 4px base grid
 *   - Border radius: 8px default
 *
 * Usage:
 *   <script src="components/ui-kit.jsx" type="text/babel"></script>
 *   <script type="text/babel">
 *     const { Button, Card, Badge, Input, Modal, Toast, Navbar, Sidebar } = window.UIKit;
 *   </script>
 *
 * All components accept a `style` prop for overrides and a `className` prop.
 */

(function () {
  const React = window.React;
  const { useState, useEffect, useRef, useCallback, createPortal } = React;
  const e = React.createElement;

  // ── Default tokens (override with CSS custom properties) ────────────
  const tokens = {
    colorPrimary: 'oklch(0.55 0.15 250)',
    colorPrimaryHover: 'oklch(0.48 0.17 250)',
    colorSurface: 'oklch(0.97 0.01 80)',
    colorSurfaceElevated: 'oklch(0.99 0.005 80)',
    colorInk: 'oklch(0.20 0.02 250)',
    colorInkMuted: 'oklch(0.55 0.02 250)',
    colorBorder: 'oklch(0.88 0.01 250)',
    colorError: 'oklch(0.55 0.22 25)',
    colorSuccess: 'oklch(0.60 0.18 145)',
    colorWarning: 'oklch(0.70 0.15 80)',
    fontDisplay: "'Source Serif 4', Georgia, serif",
    fontBody: "'Inter', -apple-system, system-ui, sans-serif",
    fontMono: "'JetBrains Mono', 'SF Mono', monospace",
    radius: '8px',
    radiusSm: '4px',
    radiusLg: '12px',
    radiusFull: '9999px',
    shadowSm: '0 1px 2px oklch(0 0 0 / 0.05)',
    shadowMd: '0 4px 12px oklch(0 0 0 / 0.08)',
    shadowLg: '0 8px 24px oklch(0 0 0 / 0.12)',
  };

  // ── Inject default CSS custom properties ────────────────────────────
  const injectTokens = () => {
    if (document.getElementById('uikit-tokens')) return;
    const style = document.createElement('style');
    style.id = 'uikit-tokens';
    style.textContent = `
      :root {
        --uk-primary: ${tokens.colorPrimary};
        --uk-primary-hover: ${tokens.colorPrimaryHover};
        --uk-surface: ${tokens.colorSurface};
        --uk-surface-elevated: ${tokens.colorSurfaceElevated};
        --uk-ink: ${tokens.colorInk};
        --uk-ink-muted: ${tokens.colorInkMuted};
        --uk-border: ${tokens.colorBorder};
        --uk-error: ${tokens.colorError};
        --uk-success: ${tokens.colorSuccess};
        --uk-warning: ${tokens.colorWarning};
        --uk-font-display: ${tokens.fontDisplay};
        --uk-font-body: ${tokens.fontBody};
        --uk-font-mono: ${tokens.fontMono};
        --uk-radius: ${tokens.radius};
        --uk-radius-sm: ${tokens.radiusSm};
        --uk-radius-lg: ${tokens.radiusLg};
        --uk-shadow-sm: ${tokens.shadowSm};
        --uk-shadow-md: ${tokens.shadowMd};
        --uk-shadow-lg: ${tokens.shadowLg};
      }
      @keyframes uk-toast-in {
        from { opacity: 0; transform: translateY(16px) scale(0.96); }
        to { opacity: 1; transform: translateY(0) scale(1); }
      }
      @keyframes uk-toast-out {
        from { opacity: 1; transform: translateY(0) scale(1); }
        to { opacity: 0; transform: translateY(-8px) scale(0.96); }
      }
      @keyframes uk-modal-in {
        from { opacity: 0; transform: scale(0.95); }
        to { opacity: 1; transform: scale(1); }
      }
      @keyframes uk-backdrop-in {
        from { opacity: 0; }
        to { opacity: 1; }
      }
    `;
    document.head.appendChild(style);
  };

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', injectTokens);
    } else {
      injectTokens();
    }
  }

  // ── Utility: merge styles ───────────────────────────────────────────
  const merge = (...styles) => Object.assign({}, ...styles.filter(Boolean));

  // ── Button ──────────────────────────────────────────────────────────
  function Button({
    children, variant = 'primary', size = 'md', disabled = false,
    onClick, style, className, icon, loading, ...rest
  }) {
    const [hovered, setHovered] = useState(false);
    const [pressed, setPressed] = useState(false);

    const sizeStyles = {
      sm: { padding: '6px 12px', fontSize: 13, height: 32 },
      md: { padding: '8px 20px', fontSize: 14, height: 40 },
      lg: { padding: '12px 28px', fontSize: 16, height: 48 },
    }[size];

    const variantStyles = {
      primary: {
        background: hovered ? 'var(--uk-primary-hover)' : 'var(--uk-primary)',
        color: 'white',
        border: 'none',
      },
      secondary: {
        background: hovered ? 'oklch(0.94 0.01 250)' : 'transparent',
        color: 'var(--uk-ink)',
        border: '1px solid var(--uk-border)',
      },
      ghost: {
        background: hovered ? 'oklch(0.95 0.01 250)' : 'transparent',
        color: 'var(--uk-ink)',
        border: '1px solid transparent',
      },
      destructive: {
        background: hovered ? 'oklch(0.48 0.24 25)' : 'var(--uk-error)',
        color: 'white',
        border: 'none',
      },
    }[variant];

    const baseStyle = merge(
      {
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        gap: 8, borderRadius: 'var(--uk-radius)', cursor: disabled ? 'not-allowed' : 'pointer',
        fontFamily: 'var(--uk-font-body)', fontWeight: 500, lineHeight: 1,
        transition: 'all 0.15s ease', opacity: disabled ? 0.5 : 1,
        transform: pressed ? 'scale(0.97)' : 'scale(1)',
        whiteSpace: 'nowrap',
      },
      sizeStyles,
      variantStyles,
      style,
    );

    return e('button', {
      style: baseStyle, className, disabled,
      onClick: disabled ? undefined : onClick,
      onMouseEnter: () => setHovered(true),
      onMouseLeave: () => { setHovered(false); setPressed(false); },
      onMouseDown: () => setPressed(true),
      onMouseUp: () => setPressed(false),
      ...rest,
    },
      loading && e('span', {
        style: {
          width: 14, height: 14, border: '2px solid currentColor',
          borderTopColor: 'transparent', borderRadius: '50%',
          animation: 'spin 0.6s linear infinite', display: 'inline-block',
        },
      }),
      icon && !loading && e('span', { style: { display: 'inline-flex' } }, icon),
      children,
    );
  }

  // ── Card ────────────────────────────────────────────────────────────
  function Card({
    children, variant = 'default', padding = 24,
    onClick, style, className, ...rest
  }) {
    const [hovered, setHovered] = useState(false);
    const interactive = !!onClick;

    const variantStyles = {
      default: {
        background: 'var(--uk-surface-elevated)',
        border: '1px solid var(--uk-border)',
        boxShadow: 'var(--uk-shadow-sm)',
      },
      elevated: {
        background: 'var(--uk-surface-elevated)',
        border: '1px solid transparent',
        boxShadow: hovered && interactive ? 'var(--uk-shadow-lg)' : 'var(--uk-shadow-md)',
      },
      outlined: {
        background: 'transparent',
        border: '1px solid var(--uk-border)',
        boxShadow: 'none',
      },
    }[variant];

    return e('div', {
      style: merge(
        {
          borderRadius: 'var(--uk-radius-lg)', padding,
          transition: 'box-shadow 0.2s ease, transform 0.15s ease',
          cursor: interactive ? 'pointer' : 'default',
          transform: hovered && interactive ? 'translateY(-2px)' : 'none',
        },
        variantStyles,
        style,
      ),
      className,
      onClick,
      onMouseEnter: () => setHovered(true),
      onMouseLeave: () => setHovered(false),
      ...rest,
    }, children);
  }

  // ── Badge ───────────────────────────────────────────────────────────
  function Badge({
    children, variant = 'default', size = 'sm', style, className,
  }) {
    const colors = {
      default: { bg: 'oklch(0.92 0.02 250)', text: 'var(--uk-ink)' },
      primary: { bg: 'oklch(0.90 0.06 250)', text: 'var(--uk-primary)' },
      success: { bg: 'oklch(0.92 0.06 145)', text: 'oklch(0.40 0.15 145)' },
      warning: { bg: 'oklch(0.92 0.06 80)', text: 'oklch(0.45 0.15 80)' },
      error: { bg: 'oklch(0.92 0.06 25)', text: 'oklch(0.45 0.18 25)' },
    }[variant];

    const sizeStyles = {
      sm: { padding: '2px 8px', fontSize: 11 },
      md: { padding: '4px 12px', fontSize: 13 },
    }[size];

    return e('span', {
      style: merge(
        {
          display: 'inline-flex', alignItems: 'center',
          borderRadius: 'var(--uk-radius-sm)',
          fontFamily: 'var(--uk-font-body)', fontWeight: 500,
          lineHeight: 1.4, whiteSpace: 'nowrap',
          background: colors.bg, color: colors.text,
        },
        sizeStyles,
        style,
      ),
      className,
    }, children);
  }

  // ── Input ───────────────────────────────────────────────────────────
  function Input({
    label, error, helper, type = 'text', placeholder,
    value, onChange, disabled, style, className, ...rest
  }) {
    const [focused, setFocused] = useState(false);
    const id = rest.id || 'input-' + Math.random().toString(36).slice(2, 8);

    return e('div', { style: merge({ display: 'flex', flexDirection: 'column', gap: 4 }, style), className },
      label && e('label', {
        htmlFor: id,
        style: {
          fontSize: 13, fontWeight: 500, color: 'var(--uk-ink)',
          fontFamily: 'var(--uk-font-body)',
        },
      }, label),
      e('input', {
        id, type, placeholder, value, onChange, disabled,
        onFocus: () => setFocused(true),
        onBlur: () => setFocused(false),
        style: {
          padding: '8px 12px', fontSize: 14, lineHeight: 1.5,
          fontFamily: 'var(--uk-font-body)',
          border: `1px solid ${error ? 'var(--uk-error)' : focused ? 'var(--uk-primary)' : 'var(--uk-border)'}`,
          borderRadius: 'var(--uk-radius)',
          outline: 'none', background: 'white',
          boxShadow: focused ? `0 0 0 3px oklch(0.55 0.15 250 / 0.12)` : 'none',
          transition: 'border-color 0.15s, box-shadow 0.15s',
          opacity: disabled ? 0.5 : 1,
          width: '100%', boxSizing: 'border-box',
        },
        ...rest,
      }),
      (error || helper) && e('span', {
        style: {
          fontSize: 12, color: error ? 'var(--uk-error)' : 'var(--uk-ink-muted)',
          fontFamily: 'var(--uk-font-body)',
        },
      }, error || helper),
    );
  }

  // ── Modal ───────────────────────────────────────────────────────────
  function Modal({ open, onClose, title, children, footer, width = 480, style }) {
    if (!open) return null;

    return e('div', {
      style: {
        position: 'fixed', inset: 0, zIndex: 10000,
        display: 'grid', placeItems: 'center',
        padding: 24,
      },
      onClick: (ev) => { if (ev.target === ev.currentTarget) onClose?.(); },
    },
      // Backdrop
      e('div', {
        style: {
          position: 'fixed', inset: 0,
          background: 'oklch(0 0 0 / 0.4)',
          animation: 'uk-backdrop-in 0.2s ease',
        },
      }),
      // Dialog
      e('div', {
        style: merge(
          {
            position: 'relative', zIndex: 1,
            background: 'white', borderRadius: 'var(--uk-radius-lg)',
            boxShadow: 'var(--uk-shadow-lg)',
            width: '100%', maxWidth: width, maxHeight: '85vh',
            display: 'flex', flexDirection: 'column',
            animation: 'uk-modal-in 0.2s ease',
          },
          style,
        ),
      },
        // Header
        title && e('div', {
          style: {
            padding: '20px 24px 0', display: 'flex',
            justifyContent: 'space-between', alignItems: 'center',
          },
        },
          e('h3', {
            style: {
              margin: 0, fontSize: 18, fontWeight: 600,
              fontFamily: 'var(--uk-font-display)', color: 'var(--uk-ink)',
            },
          }, title),
          e('button', {
            onClick: onClose,
            style: {
              background: 'none', border: 'none', cursor: 'pointer',
              fontSize: 20, color: 'var(--uk-ink-muted)', padding: 4,
              lineHeight: 1,
            },
          }, '×'),
        ),
        // Body
        e('div', {
          style: { padding: 24, overflow: 'auto', flex: 1 },
        }, children),
        // Footer
        footer && e('div', {
          style: {
            padding: '16px 24px', borderTop: '1px solid var(--uk-border)',
            display: 'flex', justifyContent: 'flex-end', gap: 8,
          },
        }, footer),
      ),
    );
  }

  // ── Toast ───────────────────────────────────────────────────────────
  function Toast({ message, variant = 'default', visible, onDismiss, duration = 4000 }) {
    useEffect(() => {
      if (visible && duration > 0) {
        const timer = setTimeout(() => onDismiss?.(), duration);
        return () => clearTimeout(timer);
      }
    }, [visible, duration, onDismiss]);

    if (!visible) return null;

    const colors = {
      default: { bg: 'var(--uk-ink)', text: 'white' },
      success: { bg: 'var(--uk-success)', text: 'white' },
      error: { bg: 'var(--uk-error)', text: 'white' },
      warning: { bg: 'var(--uk-warning)', text: 'var(--uk-ink)' },
    }[variant];

    return e('div', {
      style: {
        position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)',
        zIndex: 10001, background: colors.bg, color: colors.text,
        padding: '12px 24px', borderRadius: 'var(--uk-radius)',
        boxShadow: 'var(--uk-shadow-lg)',
        fontFamily: 'var(--uk-font-body)', fontSize: 14, fontWeight: 500,
        animation: 'uk-toast-in 0.3s ease',
        display: 'flex', alignItems: 'center', gap: 12,
        maxWidth: 400,
      },
    },
      e('span', null, message),
      onDismiss && e('button', {
        onClick: onDismiss,
        style: {
          background: 'none', border: 'none', color: 'inherit',
          cursor: 'pointer', fontSize: 16, padding: 0, lineHeight: 1,
          opacity: 0.7,
        },
      }, '×'),
    );
  }

  // ── Navbar ──────────────────────────────────────────────────────────
  function Navbar({ brand, items = [], actions, style, className }) {
    return e('nav', {
      style: merge(
        {
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 24px', height: 56,
          background: 'var(--uk-surface-elevated)',
          borderBottom: '1px solid var(--uk-border)',
          fontFamily: 'var(--uk-font-body)',
        },
        style,
      ),
      className,
    },
      // Brand
      e('div', {
        style: {
          fontSize: 18, fontWeight: 600,
          fontFamily: 'var(--uk-font-display)', color: 'var(--uk-ink)',
        },
      }, brand),
      // Items
      items.length > 0 && e('div', {
        style: { display: 'flex', gap: 24, alignItems: 'center' },
      }, items.map((item, i) =>
        e('a', {
          key: i, href: item.href || '#',
          onClick: item.onClick,
          style: {
            fontSize: 14, color: item.active ? 'var(--uk-primary)' : 'var(--uk-ink-muted)',
            textDecoration: 'none', fontWeight: item.active ? 500 : 400,
            transition: 'color 0.15s',
          },
        }, item.label)
      )),
      // Actions
      actions && e('div', {
        style: { display: 'flex', gap: 8, alignItems: 'center' },
      }, actions),
    );
  }

  // ── Sidebar ─────────────────────────────────────────────────────────
  function Sidebar({
    items = [], header, footer, width = 240,
    collapsed = false, style, className,
  }) {
    const w = collapsed ? 64 : width;

    return e('aside', {
      style: merge(
        {
          width: w, minHeight: '100vh',
          background: 'var(--uk-surface)', borderRight: '1px solid var(--uk-border)',
          display: 'flex', flexDirection: 'column',
          fontFamily: 'var(--uk-font-body)',
          transition: 'width 0.2s ease',
          overflow: 'hidden',
        },
        style,
      ),
      className,
    },
      // Header
      header && e('div', {
        style: {
          padding: collapsed ? '16px 12px' : '16px 20px',
          borderBottom: '1px solid var(--uk-border)',
        },
      }, header),
      // Items
      e('div', {
        style: { flex: 1, padding: '8px 0', overflow: 'auto' },
      }, items.map((item, i) =>
        e('div', {
          key: i, onClick: item.onClick,
          style: {
            display: 'flex', alignItems: 'center', gap: 12,
            padding: collapsed ? '10px 20px' : '10px 20px',
            cursor: 'pointer', fontSize: 14,
            color: item.active ? 'var(--uk-primary)' : 'var(--uk-ink)',
            fontWeight: item.active ? 500 : 400,
            background: item.active ? 'oklch(0.55 0.15 250 / 0.08)' : 'transparent',
            borderRadius: 0,
            transition: 'background 0.15s',
          },
        },
          item.icon && e('span', {
            style: { display: 'inline-flex', width: 20, justifyContent: 'center' },
          }, item.icon),
          !collapsed && e('span', null, item.label),
        )
      )),
      // Footer
      footer && e('div', {
        style: {
          padding: collapsed ? '16px 12px' : '16px 20px',
          borderTop: '1px solid var(--uk-border)',
        },
      }, footer),
    );
  }

  // ── Export ──────────────────────────────────────────────────────────
  const UIKit = { Button, Card, Badge, Input, Modal, Toast, Navbar, Sidebar };
  if (typeof window !== 'undefined') {
    window.UIKit = UIKit;
  }
})();
