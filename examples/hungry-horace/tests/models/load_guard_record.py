"""LoadGuardRecord copies guard record B (4 first ... 1 last; other values the last) to GuardRecord and notes it in GuardRecordPtr."""
ROUTINE = 'LoadGuardRecord'
INPUTS = ['B', 'GuardRecords (memory)']
OUTPUTS = {'regs': [], 'mem': [('GuardRecordPtr', 2), ('GuardRecord', const('GUARD_RECORD_SIZE'))]}
KINDS = ['guard', 'other-b']


def cases(rnd):
    size = const('GUARD_RECORD_SIZE')
    for b in [4, 3, 2, 1] * 5 + [0, 5, 6, 0x80, 255]:
        recs = bytes(rnd.randrange(256) for _ in range(4 * size))
        yield 'guard' if 1 <= b <= 4 else 'other-b', {
            'B': b, 'mem': {sym('GuardRecords'): recs,
                            sym('GuardRecord'): bytes(rnd.randrange(256) for _ in range(size))}}


def port(regs):
    import guards
    guards.LoadGuardRecord(regs['B'])
    return {}
