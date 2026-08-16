import pefile
from capstone import *

DLL = r"E:\逆向工程\苍蓝誓约项目\blueoath\blueoath\GameAssembly.dll"
pe = pefile.PE(DLL)
img = pe.get_memory_mapped_image()

def dis(rva, n=220, base=0x10000000):
    code = img[rva:rva+n]
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    md.detail = True
    print(f"=== disassemble {rva:#x} ({n} bytes) ===")
    for ins in md.disasm(code, base + rva):
        print(f"  {ins.address:#x}: {ins.mnemonic:8s} {ins.op_str}")

if __name__ == "__main__":
    import sys
    for t in sys.argv[1:]:
        dis(int(t, 16))
        print()
