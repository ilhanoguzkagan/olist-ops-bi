"""Build dashboard/index.html: a self-contained, single-page operations dashboard."""
from html import escape
from pathlib import Path

import plotly.graph_objects as go
from plotly.offline import get_plotlyjs_version
from plotly.subplots import make_subplots

from kpis import ROOT, findings, load_kpis

NAVY, TEAL, RED, AMBER, GREY = "#1f3a5f", "#2a9d8f", "#d1495b", "#e9a03b", "#8d99ae"
FONT = "Inter, -apple-system, Segoe UI, Roboto, sans-serif"


def style(fig, title, height=380):
    fig.update_layout(
        title=dict(text=title, x=0.01, font=dict(size=15, color=NAVY)),
        height=height, margin=dict(l=10, r=10, t=56, b=20),
        font=dict(family=FONT, size=12, color="#2b2d42"),
        paper_bgcolor="white", plot_bgcolor="white",
        legend=dict(orientation="h", y=-0.22), hoverlabel=dict(font_family=FONT),
    )
    fig.update_xaxes(gridcolor="#eef0f3", zeroline=False)
    fig.update_yaxes(gridcolor="#eef0f3", zeroline=False)
    return fig


def charts(k):
    m = k["monthly_trend"]
    fig1 = make_subplots(specs=[[{"secondary_y": True}]])
    fig1.add_bar(x=m.year_month, y=m.orders_placed, name="Orders placed", marker_color="#c9d6e8")
    fig1.add_scatter(x=m.year_month, y=m.on_time_rate, name="On-time rate", mode="lines+markers",
                     line=dict(color=NAVY, width=3), secondary_y=True)
    fig1.update_yaxes(tickformat=".0%", range=[0.75, 1], dtick=0.05, secondary_y=True)
    style(fig1, "Demand vs on-time delivery by purchase month")

    r = k["review_vs_lateness"]
    labels = r.lateness_bucket.str[3:]
    fig2 = make_subplots(specs=[[{"secondary_y": True}]])
    fig2.add_bar(x=labels, y=r.avg_review, name="Average rating (1-5)",
                 marker_color=[TEAL] + [RED] * (len(r) - 1), text=r.avg_review.round(2), textposition="outside")
    fig2.add_scatter(x=labels, y=r.share_1_2_star, name="Share of 1-2 star reviews", mode="lines+markers",
                     line=dict(color=AMBER, width=3), secondary_y=True)
    fig2.update_yaxes(range=[0, 5.2], secondary_y=False)
    fig2.update_yaxes(tickformat=".0%", range=[0, 1.04], dtick=0.25, showgrid=False, secondary_y=True)
    style(fig2, "Customer rating by days late")

    s = k["lead_time_components"]
    fig3 = go.Figure()
    for col, name, color in [("approval_days", "Payment approval", GREY),
                             ("seller_handling_days", "Seller handling", AMBER),
                             ("carrier_transit_days", "Carrier transit", NAVY)]:
        fig3.add_bar(y=s.delivery_outcome, x=s[col], name=name, orientation="h", marker_color=color,
                     text=s[col].round(1), textposition="inside")
    fig3.update_layout(barmode="stack")
    style(fig3, "Where the delivery time goes (average days per stage)", 300)

    c = k["late_root_cause"]
    fig4 = go.Figure(go.Bar(x=c.handover, y=c.late_rate, marker_color=[NAVY, RED],
                            text=[f"{v:.1%}" for v in c.late_rate], textposition="outside",
                            customdata=c.late_orders, hovertemplate="%{x}<br>Late rate %{y:.1%}<br>Late orders %{customdata:,}<extra></extra>"))
    fig4.update_yaxes(tickformat=".0%", range=[0, c.late_rate.max() * 1.25])
    style(fig4, "Late-delivery rate by seller hand-over performance", 300)

    st = k["customer_state"].query("orders >= 300").sort_values("on_time_rate")
    fig5 = go.Figure(go.Bar(x=st.customer_state, y=st.on_time_rate, marker=dict(color=st.on_time_rate, colorscale=[[0, RED], [0.5, AMBER], [1, TEAL]]),
                            text=[f"{v:.0%}" for v in st.on_time_rate], textposition="outside", textfont_size=10,
                            customdata=st.orders, hovertemplate="%{x}<br>On time %{y:.1%}<br>%{customdata:,} orders<extra></extra>"))
    fig5.update_yaxes(tickformat=".0%", range=[0, 1.08])
    style(fig5, "On-time rate by destination state (300+ orders)")

    ln = k["lane_performance"].nsmallest(10, "on_time_rate").sort_values("on_time_rate", ascending=False)
    fig6 = go.Figure(go.Bar(y=ln.lane, x=ln.on_time_rate, orientation="h", marker_color=RED,
                            text=[f"{r:.1%}  ·  {o:,} orders" for r, o in zip(ln.on_time_rate, ln.orders)], textposition="inside",
                            hovertemplate="%{y}<br>On time %{x:.1%}<extra></extra>"))
    fig6.update_xaxes(tickformat=".0%", range=[0, 1])
    style(fig6, "10 weakest shipping lanes (seller -> customer state, 300+ orders)")

    sc = k["seller_scorecard"]
    fig7 = go.Figure()
    for tier, color in [("A - Top performer", TEAL), ("B - Monitor", GREY), ("C - Needs improvement plan", RED)]:
        t = sc[sc.tier == tier]
        fig7.add_scatter(x=t.on_time_rate, y=t.avg_review, mode="markers", name=tier,
                         marker=dict(color=color, size=(t.orders ** 0.5) * 0.9, opacity=0.7, line=dict(width=0)),
                         customdata=t[["orders", "gmv_brl"]],
                         hovertemplate="On time %{x:.1%}<br>Rating %{y:.2f}<br>%{customdata[0]:,} orders<br>BRL %{customdata[1]:,.0f}<extra></extra>")
    fig7.update_xaxes(tickformat=".0%", title="On-time rate")
    fig7.update_yaxes(title="Average rating")
    style(fig7, "Seller scorecard (bubble size = orders)")

    cat = k["category_performance"].nlargest(12, "gmv_brl").sort_values("freight_to_price_ratio")
    fig8 = go.Figure(go.Bar(y=cat.category.str.replace("_", " "), x=cat.freight_to_price_ratio, orientation="h",
                            marker_color=TEAL, text=[f"{v:.0%}" for v in cat.freight_to_price_ratio], textposition="outside",
                            customdata=cat.gmv_brl, hovertemplate="%{y}<br>Freight / price %{x:.1%}<br>GMV BRL %{customdata:,.0f}<extra></extra>"))
    fig8.update_xaxes(tickformat=".0%", range=[0, cat.freight_to_price_ratio.max() * 1.25])
    style(fig8, "Freight cost as % of item price - top 12 categories by GMV")

    return [fig1, fig2, fig3, fig4, fig5, fig6, fig7, fig8]


def main():
    k = load_kpis()
    h = k["headline"].iloc[0]
    cards = [
        ("Orders delivered", f"{h.orders_delivered:,.0f}", f"of {h.orders_placed:,.0f} placed"),
        ("GMV", f"BRL {h.gmv_brl / 1e6:.1f}M", "merchandise value"),
        ("On-time rate", f"{h.on_time_rate:.1%}", "delivered by promised date"),
        ("Median lead time", f"{h.median_lead_time_days:.1f} d", f"promised {h.avg_promised_days:.1f} d on average"),
        ("Rating: on time vs late", f"{h.avg_review_on_time:.2f} / {h.avg_review_late:.2f}", "average review score"),
        ("Freight / item price", f"{h.freight_to_price_ratio:.1%}", "delivered orders"),
    ]
    figs = [f.to_html(full_html=False, include_plotlyjs=False, config={"displayModeBar": False, "responsive": True})
            for f in charts(k)]
    card_html = "".join(f'<div class="card"><div class="label">{escape(a)}</div><div class="value">{escape(b)}</div>'
                        f'<div class="sub">{escape(c)}</div></div>' for a, b, c in cards)
    finding_html = "".join(f"<li><strong>{escape(t)}.</strong> {escape(s)}</li>" for t, s in findings(k))
    chart_html = "".join(f'<section class="chart">{f}</section>' for f in figs)

    html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Olist Operations BI</title>
<script src="https://cdn.plot.ly/plotly-{get_plotlyjs_version()}.min.js"></script>
<style>
  :root {{ --navy:{NAVY}; --text:#2b2d42; --muted:#6c757d; --bg:#f5f7fa; }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; font-family:{FONT}; color:var(--text); background:var(--bg); }}
  header {{ background:var(--navy); color:white; padding:28px 16px; }}
  .wrap {{ max-width:1200px; margin:0 auto; padding:0 16px; }}
  h1 {{ margin:0 0 6px; font-size:26px; }}
  header p {{ margin:0; opacity:.85; }}
  .cards {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(170px,1fr)); gap:12px; margin:20px 0; }}
  .card {{ background:white; border-radius:10px; padding:14px 16px; box-shadow:0 1px 3px rgba(0,0,0,.06); }}
  .label {{ font-size:12px; color:var(--muted); text-transform:uppercase; letter-spacing:.04em; }}
  .value {{ font-size:24px; font-weight:700; color:var(--navy); margin:4px 0; }}
  .sub {{ font-size:12px; color:var(--muted); }}
  .findings {{ background:white; border-radius:10px; padding:16px 20px; box-shadow:0 1px 3px rgba(0,0,0,.06); }}
  .findings h2 {{ margin:0 0 8px; font-size:17px; color:var(--navy); }}
  .findings li {{ margin:6px 0; line-height:1.45; }}
  .grid {{ display:grid; grid-template-columns:1fr 1fr; gap:16px; margin:20px 0; }}
  .chart {{ background:white; border-radius:10px; padding:6px; box-shadow:0 1px 3px rgba(0,0,0,.06); min-width:0; }}
  footer {{ color:var(--muted); font-size:12px; padding:8px 0 32px; }}
  @media (max-width: 800px) {{ .grid {{ grid-template-columns:1fr; }} h1 {{ font-size:21px; }} }}
</style></head>
<body>
<header><div class="wrap"><h1>Olist E-commerce Operations BI</h1>
<p>Delivery performance and its commercial impact &middot; Brazilian marketplace orders, Jan 2017 - Aug 2018</p></div></header>
<main class="wrap">
<div class="cards">{card_html}</div>
<div class="findings"><h2>Key findings</h2><ol>{finding_html}</ol></div>
<div class="grid">{chart_html}</div>
<footer>Built by Oguzkagan Ilhan with Python, DuckDB SQL (star schema) and Plotly. Data: Olist public e-commerce dataset (CC BY-NC-SA 4.0).
Delivery KPIs use delivered orders purchased Jan 2017 - Aug 2018; see the project README for definitions and data-quality notes.</footer>
</main></body></html>
"""
    out = ROOT / "dashboard" / "index.html"
    out.parent.mkdir(exist_ok=True)
    out.write_text(html)
    assert html.count('class="chart"') == 8
    print(f"wrote {out.relative_to(ROOT)} ({len(html) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
