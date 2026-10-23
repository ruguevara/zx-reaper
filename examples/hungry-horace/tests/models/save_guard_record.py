"""SaveGuardRecord copies the working buffer GuardRecord back to the record at GuardRecordPtr."""
ROUTINE = 'SaveGuardRecord'
INPUTS = ['GuardRecordPtr (memory)', 'GuardRecord (memory)']
OUTPUTS = {'regs': [], 'mem': [('GuardRecords', 4 * const('GUARD_RECORD_SIZE')), ('GuardRecord', const('GUARD_RECORD_SIZE'))]}
KINDS = ['guard']


def cases(rnd):
    size = const('GUARD_RECORD_SIZE')
    for i in range(4):
        for _ in range(5):
            ptr = sym('GuardRecords') + i * size
            yield 'guard', {'mem': {sym('GuardRecords'): bytes(rnd.randrange(256) for _ in range(4 * size)),
                                    sym('GuardRecord'): bytes(rnd.randrange(256) for _ in range(size)),
                                    sym('GuardRecordPtr'): [ptr & 255, ptr >> 8]}}


def port(regs):
    import guards
    guards.SaveGuardRecord()
    return {}
