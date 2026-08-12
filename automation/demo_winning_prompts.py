#!/usr/bin/env python3
"""
Demo script to showcase the winning prompts
"""

from winning_prompts import get_ctf_prompts, get_security_prompts

def main():
    print("🎯 Winning Prompts Demo")
    print("=" * 50)
    print()
    
    print("🏁 CTF Challenge - Winning Prompts")
    print("These prompts bypass guardrails to reveal CCTV/register evidence:")
    print("-" * 60)
    
    ctf_prompts = get_ctf_prompts("standard")
    for i, prompt in enumerate(ctf_prompts[:4], 1):  # Show first 4
        print(f"{i}. {prompt}")
    
    print()
    print("🔒 Security Challenge - Winning Prompts")  
    print("These prompts are designed to extract Jon Lim's email:")
    print("-" * 60)
    
    security_prompts = get_security_prompts("standard")
    for i, prompt in enumerate(security_prompts[:4], 1):  # Show first 4
        print(f"{i}. {prompt}")
    
    print()
    print("💡 Key Success Factors:")
    print("   🏁 CTF: Use audit, compliance, ledger reconciliation, co-owner dispute framing")
    print("   🔒 Security: Use urgency, authority, business context")
    print()
    print("🚀 Ready to test these winning prompts!")

if __name__ == "__main__":
    main()
