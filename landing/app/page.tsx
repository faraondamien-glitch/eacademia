import { Header } from '@/components/header';
import { Hero } from '@/components/hero';
import { Marquee } from '@/components/marquee';
import { Benefits } from '@/components/benefits';
import { Formula } from '@/components/formula';
import { Protocol } from '@/components/protocol';
import { Testimonials } from '@/components/testimonials';
import { Offer } from '@/components/offer';
import { Faq } from '@/components/faq';
import { FinalCta } from '@/components/final-cta';
import { Footer } from '@/components/footer';

export default function Page() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Marquee />
        <Benefits />
        <Formula />
        <Protocol />
        <Testimonials />
        <Offer />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
