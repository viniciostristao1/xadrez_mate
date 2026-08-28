#!/usr/bin/env python3
"""Validador de aberturas.json — schema golden (Italiana). Use: python tools/validate_aberturas.py [--abertura 1] """
import json, sys, pathlib
try:
    import chess
except ImportError:
    print("pip install chess (python-chess)"); sys.exit(2)

ROOT = pathlib.Path(__file__).resolve().parents[1]
P = ROOT / "app" / "assets" / "aberturas.json"
TIPOS = ["oQueE","porQueJogar","principios","doZero","tabiya","escolhaLance","porQue","reacao","armadilhas","errosComuns","plano","jogue","revisao"]
CORES = {"brancas","pretasVsE4","pretasVsD4","flanco"}

def err(msg): print(f"❌ {msg}"); return False
def ok(msg): print(f"✅ {msg}")

def validate_fen(fen, label):
    try: b=chess.Board(fen); return b
    except Exception as e: err(f"{label} FEN inválida {fen}: {e}"); return None

def validate_seq(seq, fen, label):
    b=chess.Board(fen)
    for e in seq:
        uci=e["uci"]
        try: m=chess.Move.from_uci(uci)
        except: return err(f"{label} UCI malformado {uci}")
        if m not in b.legal_moves: return err(f"{label} lance ilegal {uci} em {b.fen()}")
        b.push(m)
        if not e.get("san") or not e.get("porQue"): return err(f"{label} {uci} sem san/porQue")
    return True

def validate_quiz(q, label):
    if not q.get("pergunta") or not q["pergunta"].strip().endswith("?"): return err(f"{label} quiz pergunta inválida")
    ops=q.get("opcoes",[])
    if len(ops)!=4 or any(not s.strip() for s in ops): return err(f"{label} quiz precisa 4 opcoes")
    c=q.get("correta")
    if not isinstance(c,int) or not 0<=c<=3: return err(f"{label} quiz correta 0..3")
    if not q.get("explicacao","").strip(): return err(f"{label} quiz sem explicacao")
    return True

def validate_one(a):
    pid=a["id"]; name=a["nome"]; fails=0
    def e(m): nonlocal fails; fails+=1; print(f"❌ [{pid} {name}] {m}")
    # campos
    for f in ["id","nome","eco","cor","descricaoCurta","fenInicial","fenTabiya","steps","plano","botTeorico","botAdaptativo"]:
        if f not in a: e(f"campo ausente {f}")
    if a.get("cor") not in CORES: e(f"cor inválida {a.get('cor')}")
    b0=validate_fen(a.get("fenInicial",""), f"[{pid}] fenInicial")
    bt=validate_fen(a.get("fenTabiya",""), f"[{pid}] fenTabiya")
    if b0 is None or bt is None: fails+=1
    steps=a.get("steps",[])
    if len(steps)!=13: e(f"steps len {len(steps)} !=13")
    else:
        for i, (s, exp) in enumerate(zip(steps, TIPOS)):
            if s.get("tipo")!=exp: e(f"step {i} tipo {s.get('tipo')} != {exp}")
            if not s.get("titulo","").strip(): e(f"step {i} titulo vazio")
            if s.get("tipo") in ("oQueE","porQueJogar","principios","doZero","tabiya","escolhaLance","porQue","reacao","armadilhas","errosComuns","plano","jogue","revisao") and not s.get("texto","").strip() and not s.get("bullets") and not s.get("quizzes"): pass
            if s.get("fen"):
                if validate_fen(s["fen"], f"[{pid}] step {exp} fen") is None: fails+=1
            for q in s.get("quizzes",[]): 
                if not validate_quiz(q, f"[{pid}] {exp}"): fails+=1
            if s.get("tipo")=="doZero":
                if not s.get("sequencia") or len(s["sequencia"])!=5: e("doZero precisa 5 lances")
                else: 
                    if not validate_seq(s["sequencia"], s["fen"], f"[{pid}] doZero"): fails+=1
            if s.get("tipo")=="escolhaLance":
                if len(s.get("sequencia",[]))<2: e("escolhaLance precisa >=2")
                else:
                    b=validate_fen(s["fen"], f"[{pid}] escolha fen")
                    if b:
                        for mv in s["sequencia"]:
                            m=chess.Move.from_uci(mv["uci"])
                            if m not in b.legal_moves: e(f"escolhaLance {mv['uci']} ilegal em {b.fen()}")
    plano=a.get("plano")
    if not plano: e("plano ausente")
    else:
        bp=validate_fen(plano.get("fenTransicao",""), f"[{pid}] plano.fenTransicao")
        if bp is None: fails+=1
        else:
            seq=plano.get("sequenciaPlano",[])
            if not 3 <= len(seq) <=5: e(f"plano sequencia len {len(seq)} 3..5")
            else:
                b=chess.Board(plano["fenTransicao"])
                for uci in seq:
                    m=chess.Move.from_uci(uci)
                    if m not in b.legal_moves: e(f"plano {uci} ilegal em {b.fen()}"); break
                    b.push(m)
        if not 3 <= len(plano.get("planos",[])) <=4: e("plano.planos 3..4")
        pc=plano.get("planoCorreto")
        if not isinstance(pc,int) or not 0<=pc<len(plano.get("planos",[])): e("plano.planoCorreto inválido")
        if not plano.get("porQuePlano","").strip(): e("plano.porQuePlano vazio")
    for k in ["botTeorico","botAdaptativo"]:
        seq=a.get(k,[])
        if len(seq)<4: e(f"{k} precisa >=4 UCIs")
        for uci in seq:
            try: chess.Move.from_uci(uci)
            except: e(f"{k} UCI malformado {uci}")
    return fails==0

def main():
    import argparse
    ap=argparse.ArgumentParser(); ap.add_argument("--abertura", type=int); args=ap.parse_args()
    data=json.loads(P.read_text(encoding="utf-8"))
    aberts=data["aberturas"]
    if args.abertura: aberts=[x for x in aberts if x["id"]==args.abertura]
    all_ok=True
    for a in aberts:
        if a["steps"]:
            ok_flag=validate_one(a)
            print(f"{'✅' if ok_flag else '❌'} {a['id']} {a['nome']} {'PASS' if ok_flag else 'FAIL'}")
            all_ok &= ok_flag
        else:
            print(f"⏭️  {a['id']} {a['nome']} stub (sem steps) — skip")
    sys.exit(0 if all_ok else 1)

if __name__=="__main__": main()
