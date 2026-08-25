# Generate real country symbol SVGs for all 15 languages (flat vector style,
# national-palette per language). One-time generator; output is committed.
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/../..')

W = {}

W['en'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F4F7FB'/>"
"<g fill='#0F2B5B'><rect x='24' y='42' width='30' height='40'/>"
"<rect x='58' y='34' width='20' height='48'/>"
"<polygon points='58,34 68,22 78,34'/></g>"
"<circle cx='68' cy='48' r='6' fill='#F6E7B2'/>"
"<rect x='20' y='82' width='62' height='4' rx='2' fill='#0F2B5B'/></svg>")

W['fr'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F5F7FB'/>"
"<g fill='#1B3A6B'><polygon points='50,16 30,84 38,84'/>"
"<polygon points='50,16 70,84 62,84'/>"
"<polygon points='50,16 45,84 55,84'/>"
"<rect x='26' y='66' width='48' height='5'/>"
"<rect x='33' y='52' width='34' height='4'/></g>"
"<rect x='20' y='84' width='60' height='4' rx='2' fill='#1B3A6B'/></svg>")

W['de'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F7F6F2'/>"
"<g fill='#3A3A3A'><rect x='22' y='36' width='8' height='46'/>"
"<rect x='36' y='36' width='8' height='46'/>"
"<rect x='50' y='36' width='8' height='46'/>"
"<rect x='64' y='36' width='8' height='46'/>"
"<rect x='18' y='28' width='58' height='8'/>"
"<rect x='14' y='20' width='66' height='8'/></g>"
"<rect x='18' y='82' width='58' height='4' rx='2' fill='#3A3A3A'/></svg>")

W['es'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FBF4EC'/>"
"<g fill='#B0352B'><polygon points='50,20 26,62 74,62'/>"
"<rect x='26' y='62' width='48' height='14'/>"
"<rect x='47' y='40' width='6' height='22'/>"
"<rect x='36' y='51' width='28' height='6'/></g>"
"<rect x='30' y='76' width='40' height='5' rx='2' fill='#7A241E'/></svg>")

W['it'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F7F4EE'/>"
"<g fill='#8A6A4F'><rect x='18' y='60' width='64' height='22' rx='4'/>"
"<path d='M26 60 a7 9 0 0 1 14 0 a7 9 0 0 1 14 0 a7 9 0 0 1 14 0 a7 9 0 0 1 12 0 v6 h-54z' fill='#F7F4EE'/>"
"<rect x='24' y='46' width='52' height='10' rx='3'/></g>"
"<circle cx='50' cy='34' r='6' fill='#C9A227'/></svg>")

W['pt'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F4F7F4'/>"
"<circle cx='50' cy='48' r='24' fill='#046A38'/>"
"<circle cx='50' cy='48' r='13' fill='#DA291C'/>"
"<rect x='44' y='42' width='12' height='12' rx='2' fill='#F8EFDF'/>"
"<rect x='47' y='45' width='6' height='6' fill='#DA291C'/></svg>")

W['zh'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FBF1EF'/>"
"<circle cx='50' cy='52' r='22' fill='#FFFFFF' stroke='#2B2B2B' stroke-width='2'/>"
"<circle cx='34' cy='32' r='8' fill='#2B2B2B'/>"
"<circle cx='66' cy='32' r='8' fill='#2B2B2B'/>"
"<ellipse cx='42' cy='48' rx='4.5' ry='6' fill='#2B2B2B'/>"
"<ellipse cx='58' cy='48' rx='4.5' ry='6' fill='#2B2B2B'/>"
"<ellipse cx='50' cy='60' rx='4' ry='3' fill='#2B2B2B'/></svg>")

W['ja'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FDF4F5'/>"
"<polygon points='50,18 24,74 76,74' fill='#5C7FBB'/>"
"<polygon points='50,18 42,36 58,36' fill='#FFFFFF'/>"
"<rect x='20' y='74' width='60' height='4' rx='2' fill='#8B3A4A'/></svg>")

W['ko'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FBFAF7'/>"
"<circle cx='50' cy='50' r='24' fill='#CD2E3A'/>"
"<path d='M26 50 a24 24 0 0 0 48 0 a12 12 0 0 1 -24 0 a12 12 0 0 0 -24 0z' fill='#0047A0'/></svg>")

W['ru'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F5F6FA'/>"
"<g fill='#C23B3B'><rect x='38' y='40' width='24' height='34'/>"
"<polygon points='34,40 66,40 50,22'/>"
"<polygon points='50,10 46,22 54,22'/>"
"<rect x='30' y='52' width='10' height='22'/>"
"<polygon points='28,52 42,52 35,42'/>"
"<rect x='60' y='52' width='10' height='22'/>"
"<polygon points='58,52 72,52 65,42'/></g>"
"<g fill='#E3B53C'><circle cx='50' cy='34' r='4'/>"
"<circle cx='35' cy='47' r='3'/>"
"<circle cx='65' cy='47' r='3'/></g>"
"<rect x='26' y='74' width='48' height='4' rx='2' fill='#C23B3B'/></svg>")

W['ar'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#F3F7F3'/>"
"<g fill='#3E6B3E'><path d='M50 22 c10 12 14 20 14 30 a14 14 0 0 1 -28 0 c0 -10 4 -18 14 -30z'/>"
"<rect x='46' y='62' width='8' height='14' rx='2'/>"
"<path d='M36 70 c-6 2 -10 2 -14 0 c4 6 8 8 14 8z'/>"
"<path d='M64 70 c6 2 10 2 14 0 c-4 6 -8 8 -14 8z'/></g>"
"<circle cx='50' cy='84' r='4' fill='#C9A227'/></svg>")

W['hi'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FDF7F0'/>"
"<g><ellipse cx='50' cy='66' rx='10' ry='16' fill='#E9942A'/>"
"<ellipse cx='32' cy='70' rx='9' ry='13' fill='#F2B355' transform='rotate(-24 32 70)'/>"
"<ellipse cx='68' cy='70' rx='9' ry='13' fill='#F2B355' transform='rotate(24 68 70)'/>"
"<ellipse cx='41' cy='52' rx='8' ry='12' fill='#E9942A' transform='rotate(-18 41 52)'/>"
"<ellipse cx='59' cy='52' rx='8' ry='12' fill='#E9942A' transform='rotate(18 59 52)'/>"
"<ellipse cx='50' cy='40' rx='7' ry='11' fill='#F2B355'/></g>"
"<circle cx='50' cy='30' r='4' fill='#2E6FB7'/></svg>")

W['th'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FDF6EE'/>"
"<g fill='#C78B2C'><polygon points='50,14 34,38 66,38'/>"
"<polygon points='50,30 28,56 72,56'/>"
"<polygon points='50,46 22,76 78,76'/></g>"
"<rect x='30' y='76' width='40' height='6' rx='2' fill='#8A5A1B'/></svg>")

W['tl'] = ("<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100'>"
"<rect width='100' height='100' rx='14' fill='#FDF7EC'/>"
"<circle cx='50' cy='50' r='16' fill='#FCD116'/>"
"<g stroke='#FCD116' stroke-width='5' stroke-linecap='round'>"
"<line x1='50' y1='18' x2='50' y2='28'/>"
"<line x1='50' y1='72' x2='50' y2='82'/>"
"<line x1='18' y1='50' x2='28' y2='50'/>"
"<line x1='72' y1='50' x2='82' y2='50'/>"
"<line x1='27' y1='27' x2='34' y2='34'/>"
"<line x1='66' y1='66' x2='73' y2='73'/>"
"<line x1='73' y1='27' x2='66' y2='34'/>"
"<line x1='34' y1='66' x2='27' y2='73'/></g></svg>")

for code, svg in W.items():
    path = 'assets/symbols/%s_symbol.svg' % code
    open(path, 'w', encoding='utf-8').write(svg + '\n')
    print('wrote', path)
print('total written:', len(W), '(ms already real = 15 total)')
