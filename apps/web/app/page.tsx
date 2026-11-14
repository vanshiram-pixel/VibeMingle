export default function HomePage() {
  return <main className="shell">
    <nav className="nav"><strong>VibeMingle</strong><span>Connect Beyond Borders</span></nav>
    <section className="hero">
      <p className="eyebrow">MEET • TALK • DISCOVER</p>
      <h1>Connect beyond<br/>your borders.</h1>
      <p className="lead">A new way to meet people around the world—built with consent, privacy and safety at its core.</p>
      <a className="cta" href="#safety">Explore our safety approach</a>
    </section>
    <section id="safety" className="panel">
      <h2>Safety comes first.</h2>
      <p>VibeMingle is being built for adults, with reporting, blocking and clear privacy controls. This early scaffold is not a live chat service.</p>
    </section>
    <footer>© {new Date().getFullYear()} VibeMingle · Connect Beyond Borders</footer>
  </main>;
}